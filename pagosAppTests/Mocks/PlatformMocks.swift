//
//  PlatformMocks.swift
//  pagosAppTests
//
//  Mocks for platform/external-system data sources (Calendar, Notifications).
//

import Foundation
@testable import pagosApp

// MARK: - MockCalendarEventDataSource

@MainActor
final class MockCalendarEventDataSource: CalendarEventDataSource {
    var shouldGrantAccess = true
    private(set) var addedEvents: [(title: String, dueDate: Date)] = []
    private(set) var updatedEvents: [(identifier: String, title: String, dueDate: Date, isPaid: Bool)] = []
    private(set) var removedEventIds: [String] = []

    func requestAccess() async -> Bool { shouldGrantAccess }
    func requestAccess(completion: @escaping (Bool) -> Void) { completion(shouldGrantAccess) }

    func addEvent(title: String, dueDate: Date) async -> String? {
        addedEvents.append((title: title, dueDate: dueDate))
        return "mock-event-\(UUID().uuidString)"
    }

    func addEvent(title: String, dueDate: Date, completion: @escaping (String?) -> Void) {
        addedEvents.append((title: title, dueDate: dueDate))
        completion("mock-event-\(UUID().uuidString)")
    }

    func updateEvent(eventIdentifier: String, title: String, dueDate: Date, isPaid: Bool) {
        updatedEvents.append((identifier: eventIdentifier, title: title, dueDate: dueDate, isPaid: isPaid))
    }

    func removeEvent(eventIdentifier: String) {
        removedEventIds.append(eventIdentifier)
    }
}

// MARK: - MockNotificationDataSource

@MainActor
final class MockNotificationDataSource: NotificationDataSource {
    private(set) var scheduledPaymentIds: [UUID] = []
    private(set) var cancelledPaymentIds: [UUID] = []
    private(set) var scheduledReminderIds: [UUID] = []
    private(set) var cancelledReminderIds: [UUID] = []
    private(set) var authorizationRequested = false

    func requestAuthorization() { authorizationRequested = true }

    func scheduleNotifications(
        paymentId: UUID, name: String, amount: Double,
        currencySymbol: String, dueDate: Date, isPaid: Bool
    ) {
        scheduledPaymentIds.append(paymentId)
    }

    func cancelNotifications(paymentId: UUID) {
        cancelledPaymentIds.append(paymentId)
    }

    func scheduleReminderNotifications(
        reminderId: UUID, title: String,
        dueDate: Date, notificationSettings: NotificationSettings
    ) {
        scheduledReminderIds.append(reminderId)
    }

    func cancelReminderNotifications(reminderId: UUID) {
        cancelledReminderIds.append(reminderId)
    }

    func debugPendingNotifications() async {}
}
