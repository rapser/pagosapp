//
//  PaymentOperationsService.swift
//  pagosApp
//
//  Coordinates payment CRUD operations with side effects
//  Follows Single Responsibility Principle
//

import Foundation
import SwiftData
import OSLog

/// Default implementation coordinating all payment operations
@MainActor
final class DefaultPaymentOperationsService: PaymentOperationsService {
    private let modelContext: ModelContext
    private let syncService: PaymentSyncService
    private let notificationService: NotificationService
    private let calendarService: CalendarService
    private let paymentSyncManager: PaymentSyncManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentOperations")

    init(
        modelContext: ModelContext,
        syncService: PaymentSyncService,
        notificationService: NotificationService,
        calendarService: CalendarService,
        paymentSyncManager: PaymentSyncManager
    ) {
        self.modelContext = modelContext
        self.syncService = syncService
        self.notificationService = notificationService
        self.calendarService = calendarService
        self.paymentSyncManager = paymentSyncManager
    }

    // MARK: - Create

    func createPayment(_ payment: Payment) async throws {
        logger.info("Creating payment: \(payment.name)")

        modelContext.insert(payment)
        payment.syncStatus = .local
        try modelContext.save()

        await notificationService.scheduleNotifications(for: payment)

        await calendarService.addEvent(for: payment) { [weak self] eventId in
            payment.eventIdentifier = eventId
            try? self?.modelContext.save()
        }

        // Notify that a payment changed so Settings can update pending count
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)
        }

        logger.info("✅ Payment created locally: \(payment.name)")
    }

    // MARK: - Update

    func updatePayment(_ payment: Payment) async throws {
        logger.info("Updating payment: \(payment.name)")

        if payment.syncStatus == .synced {
            payment.syncStatus = .modified
        }

        try modelContext.save()

        await notificationService.cancelNotifications(for: payment)
        if !payment.isPaid {
            await notificationService.scheduleNotifications(for: payment)
        }

        await calendarService.updateEvent(for: payment)

        // Notify that a payment changed so Settings can update pending count
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)
        }

        logger.info("✅ Payment updated locally: \(payment.name)")
    }

    // MARK: - Delete

    func deletePayment(_ payment: Payment) async throws {
        logger.info("Deleting payment: \(payment.name)")

        let paymentId = payment.id
        let wasSynced = payment.syncStatus == .synced || payment.syncStatus == .modified

        await calendarService.removeEvent(for: payment)
        await notificationService.cancelNotifications(for: payment)
        modelContext.delete(payment)
        
        try modelContext.save()
        
        // Sync deletion to server in background if payment was synced
        if wasSynced {
            Task {
                await paymentSyncManager.syncDeletePayment(paymentId)
            }
        }

        // Notify that a payment changed so Settings can update pending count
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)
        }

        logger.info("✅ Payment deleted locally: \(payment.name)")
    }
}
