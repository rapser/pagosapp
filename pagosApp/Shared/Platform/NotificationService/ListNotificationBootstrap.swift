//
//  ListNotificationBootstrap.swift
//  pagosApp
//
//  Single entry points for rescheduling local notifications after list loads.
//  Payment vs reminder policies differ; both call through here for consistency.
//

import Foundation

@MainActor
enum ListNotificationBootstrap {

    /// Payment list: reschedule local notifications once per view-model lifetime after the first successful fetch.
    static func runPaymentRescheduleIfNeeded(
        hasAlreadyRescheduled: inout Bool,
        payments: [Payment],
        useCase: SchedulePaymentNotificationsUseCase?
    ) {
        guard !hasAlreadyRescheduled, let useCase else { return }
        hasAlreadyRescheduled = true
        Task { @MainActor in
            useCase.rescheduleAll(payments)
        }
    }

    /// Reminder list: reschedule after every successful load (sync, restarts, downloaded data).
    static func runReminderRescheduleAfterFetch(
        reminders: [Reminder],
        useCase: RescheduleReminderNotificationsUseCase?
    ) {
        guard let useCase else { return }
        Task { @MainActor in
            useCase.rescheduleAll(reminders)
        }
    }
}
