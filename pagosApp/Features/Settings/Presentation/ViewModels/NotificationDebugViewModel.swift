//
//  NotificationDebugViewModel.swift
//  pagosApp
//
//  ViewModel for notification debug functionality
//  Clean Architecture - Presentation Layer
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationDebugViewModel: BaseViewModel {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var pendingCount: Int = 0
    var reminderCount: Int = 0
    var paymentCount: Int = 0
    var reminderNotifications: [String] = []
    var paymentNotifications: [String] = []
    var lastActionMessage: String = ""
    
    private let notificationDataSource: NotificationDataSource
    private let getAllRemindersUseCase: GetAllRemindersUseCase
    private let rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase
    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let schedulePaymentNotificationsUseCase: SchedulePaymentNotificationsUseCase

    init(
        notificationDataSource: NotificationDataSource,
        getAllRemindersUseCase: GetAllRemindersUseCase,
        rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase,
        getAllPaymentsUseCase: GetAllPaymentsUseCase,
        schedulePaymentNotificationsUseCase: SchedulePaymentNotificationsUseCase
    ) {
        self.notificationDataSource = notificationDataSource
        self.getAllRemindersUseCase = getAllRemindersUseCase
        self.rescheduleNotificationsUseCase = rescheduleNotificationsUseCase
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.schedulePaymentNotificationsUseCase = schedulePaymentNotificationsUseCase
        super.init(category: "NotificationDebugViewModel")
    }
    
    func refreshStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingCount = pendingRequests.count
        
        let reminderRequests = pendingRequests.filter { LocalNotificationIdentifiers.isReminderNotificationIdentifier($0.identifier) }
        let paymentRequests = pendingRequests.filter { LocalNotificationIdentifiers.isPaymentNotificationIdentifier($0.identifier) }
        
        reminderCount = reminderRequests.count
        paymentCount = paymentRequests.count
        
        reminderNotifications = reminderRequests.map { request in
            let triggerInfo = if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                "\(trigger.dateComponents.day ?? 0)/\(trigger.dateComponents.month ?? 0) \(trigger.dateComponents.hour ?? 0):\(String(format: "%02d", trigger.dateComponents.minute ?? 0))"
            } else {
                L10n.Debug.Notifications.triggerUnknown
            }
            return "\(request.content.subtitle) - \(triggerInfo)"
        }
        
        paymentNotifications = paymentRequests.map { request in
            let triggerInfo = if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                "\(trigger.dateComponents.day ?? 0)/\(trigger.dateComponents.month ?? 0) \(trigger.dateComponents.hour ?? 0):\(String(format: "%02d", trigger.dateComponents.minute ?? 0))"
            } else {
                L10n.Debug.Notifications.triggerUnknown
            }
            return "\(request.content.subtitle) - \(triggerInfo)"
        }
    }
    
    func scheduleTestNotification(title: String, dueDate: Date) {
        let testId = UUID()
        let defaultSettings = NotificationSettings()  // Use default settings for test
        notificationDataSource.scheduleReminderNotifications(
            reminderId: testId, 
            title: title, 
            dueDate: dueDate,
            notificationSettings: defaultSettings
        )
        
        lastActionMessage = L10n.Debug.Notifications.messageTestScheduled(title)
        
        // Refresh after a short delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            await refreshStatus()
        }
    }
    
    func rescheduleAllReminderNotifications() async {
        logDebug("Starting reschedule of all reminder notifications")
        lastActionMessage = L10n.Debug.Notifications.messageReschedulingReminders
        
        let result = await getAllRemindersUseCase.execute()
        
        switch result {
        case .success(let reminders):
            logDebug("Found \(reminders.count) reminders to reschedule")
            rescheduleNotificationsUseCase.rescheduleAll(reminders)
            lastActionMessage = L10n.Debug.Notifications.messageRescheduledReminders(reminders.count)

        case .failure(let error):
            logError(error)
            lastActionMessage = L10n.Debug.Notifications.messageErrorFetchReminders(error.localizedDescription)
        }
        
        // Refresh status after rescheduling
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            await refreshStatus()
        }
    }
    
    func requestAuthorization() {
        notificationDataSource.requestAuthorization()
        lastActionMessage = L10n.Debug.Notifications.messageRequestingPermission
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            await refreshStatus()
        }
    }
    
    func rescheduleAllPaymentNotifications() async {
        logDebug("Starting reschedule of all payment notifications")
        lastActionMessage = L10n.Debug.Notifications.messageReschedulingPayments

        let result = await getAllPaymentsUseCase.execute()

        switch result {
        case .success(let payments):
            logDebug("Found \(payments.count) payments to reschedule")
            schedulePaymentNotificationsUseCase.rescheduleAll(payments)
            lastActionMessage = L10n.Debug.Notifications.messageRescheduledPayments(payments.count)

        case .failure(let error):
            logError(error)
            lastActionMessage = L10n.Debug.Notifications.messageErrorFetchPayments(error.localizedDescription)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            await refreshStatus()
        }
    }

    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        lastActionMessage = L10n.Debug.Notifications.messageCancelledAll
        await refreshStatus()
    }
    
    func debugPendingNotifications() async {
        await notificationDataSource.debugPendingNotifications()
        lastActionMessage = L10n.Debug.Notifications.messageLogsToConsole
    }
}