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

        // 1. Save to local database
        modelContext.insert(payment)
        try modelContext.save()

        // 2. Schedule notifications
        notificationService.scheduleNotifications(for: payment)

        // 3. Add to calendar
        calendarService.addEvent(for: payment) { [weak self] eventId in
            payment.eventIdentifier = eventId
            try? self?.modelContext.save()
        }

        // 4. Sync to server
        try await syncService.syncPayment(payment)

        logger.info("✅ Payment created successfully: \(payment.name)")
    }

    // MARK: - Update

    func updatePayment(_ payment: Payment) async throws {
        logger.info("Updating payment: \(payment.name)")

        // 1. Save changes to local database
        try modelContext.save()

        // 2. Update notifications
        notificationService.cancelNotifications(for: payment)
        if !payment.isPaid {
            notificationService.scheduleNotifications(for: payment)
        }

        // 3. Update calendar event
        calendarService.updateEvent(for: payment)

        // 4. Sync to server
        try await syncService.syncPayment(payment)

        logger.info("✅ Payment updated successfully: \(payment.name)")
    }

    // MARK: - Delete

    func deletePayment(_ payment: Payment) async throws {
        logger.info("Deleting payment: \(payment.name)")

        // 1. Remove from calendar
        calendarService.removeEvent(for: payment)

        // 2. Cancel notifications
        notificationService.cancelNotifications(for: payment)

        // 3. Delete from local database
        modelContext.delete(payment)
        try modelContext.save()

        // 4. Sync deletion to server
        try await syncService.syncDeletePayment(payment.id)

        logger.info("✅ Payment deleted successfully: \(payment.name)")
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
