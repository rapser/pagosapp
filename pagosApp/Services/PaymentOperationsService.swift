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
    func scheduleNotifications(for payment: Payment)
    func cancelNotifications(for payment: Payment)
}

/// Protocol for calendar service (ISP + DIP)
protocol CalendarService {
    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void)
    func updateEvent(for payment: Payment)
    func removeEvent(for payment: Payment)
}

/// Protocol for payment operations (ISP)
protocol PaymentOperationsService {
    func createPayment(_ payment: Payment) async throws
    func updatePayment(_ payment: Payment) async throws
    func deletePayment(_ payment: Payment) async throws
}

/// Default implementation coordinating all payment operations
@MainActor
class DefaultPaymentOperationsService: PaymentOperationsService {
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

        notificationService.scheduleNotifications(for: payment)

        calendarService.addEvent(for: payment) { [weak self] eventId in
            payment.eventIdentifier = eventId
            try? self?.modelContext.save()
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

        notificationService.cancelNotifications(for: payment)
        if !payment.isPaid {
            notificationService.scheduleNotifications(for: payment)
        }

        calendarService.updateEvent(for: payment)

        logger.info("✅ Payment updated locally: \(payment.name)")
    }

    // MARK: - Delete

    func deletePayment(_ payment: Payment) async throws {
        logger.info("Deleting payment: \(payment.name)")

        let paymentId = payment.id
        let wasSynced = payment.syncStatus == .synced || payment.syncStatus == .modified

        calendarService.removeEvent(for: payment)
        notificationService.cancelNotifications(for: payment)

        modelContext.delete(payment)
        try modelContext.save()

        if wasSynced {
            // TODO: Track deletion for server sync in Phase 3
            logger.info("Payment \(paymentId) deletion pending sync")
        }

        logger.info("✅ Payment deleted locally: \(payment.name)")
    }
}

// MARK: - Adapter for NotificationManager

class NotificationManagerAdapter: NotificationService {
    private let manager: NotificationManager

    init(manager: NotificationManager = .shared) {
        self.manager = manager
    }

    func scheduleNotifications(for payment: Payment) {
        manager.scheduleNotification(for: payment)  // Singular
    }

    func cancelNotifications(for payment: Payment) {
        manager.cancelNotification(for: payment)    // Singular
    }
}

// MARK: - Adapter for EventKitManager

class EventKitManagerAdapter: CalendarService {
    private let manager: EventKitManager

    init(manager: EventKitManager = .shared) {
        self.manager = manager
    }

    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) {
        manager.addEvent(for: payment, completion: completion)
    }

    func updateEvent(for payment: Payment) {
        manager.updateEvent(for: payment)
    }

    func removeEvent(for payment: Payment) {
        manager.removeEvent(for: payment)
    }
}
