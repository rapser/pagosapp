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

/// Protocol for notification service (ISP + DIP)
protocol NotificationService {
    func scheduleNotifications(for payment: Payment) async
    func cancelNotifications(for payment: Payment) async
}

/// Protocol for calendar service (ISP + DIP)
protocol CalendarService {
    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) async
    func updateEvent(for payment: Payment) async
    func removeEvent(for payment: Payment) async
}

/// Protocol for payment operations (ISP)
protocol PaymentOperationsService {
    func createPayment(_ payment: Payment) async throws
    func updatePayment(_ payment: Payment) async throws
    func deletePayment(_ payment: Payment) async throws
}

/// Default implementation coordinating all payment operations
final class DefaultPaymentOperationsService: PaymentOperationsService {
    private let modelContext: ModelContext
    private let syncService: PaymentSyncService
    private let notificationService: NotificationService
    private let calendarService: CalendarService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentOperations")

    init(
        modelContext: ModelContext,
        syncService: PaymentSyncService,
        notificationService: NotificationService,
        calendarService: CalendarService
    ) {
        self.modelContext = modelContext
        self.syncService = syncService
        self.notificationService = notificationService
        self.calendarService = calendarService
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
        NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)

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
        NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)

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
                await PaymentSyncManager.shared.syncDeletePayment(paymentId)
            }
        }

        // Notify that a payment changed so Settings can update pending count
        NotificationCenter.default.post(name: NSNotification.Name("PaymentDidChange"), object: nil)

        logger.info("✅ Payment deleted locally: \(payment.name)")
    }
}

// MARK: - Adapter for NotificationManager

class NotificationManagerAdapter: NotificationService {
    private let manager: NotificationManager

    init(manager: NotificationManager = .shared) {
        self.manager = manager
    }

    func scheduleNotifications(for payment: Payment) async {
        manager.scheduleNotification(for: payment)  // Singular
    }

    func cancelNotifications(for payment: Payment) async {
        manager.cancelNotification(for: payment)    // Singular
    }
}

// MARK: - Adapter for EventKitManager

class EventKitManagerAdapter: CalendarService {
    private let manager: EventKitManager

    init(manager: EventKitManager) {
        self.manager = manager
    }
    
    convenience init() {
        self.init(manager: EventKitManager.shared)
    }

    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) async {
        manager.addEvent(for: payment, completion: completion)
    }

    func updateEvent(for payment: Payment) async {
        manager.updateEvent(for: payment)
    }

    func removeEvent(for payment: Payment) async {
        manager.removeEvent(for: payment)
    }
}
