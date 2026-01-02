//
//  CalendarEventDataSource.swift
//  pagosApp
//
//  Platform DataSource for calendar events (EventKit wrapper)
//  Clean Architecture - Data Layer (Platform)
//

import Foundation
import EventKit

/// Protocol for calendar event operations
protocol CalendarEventDataSource {
    /// Request calendar access permission
    func requestAccess(completion: @escaping (Bool) -> Void)

    /// Add calendar event for a payment
    func addEvent(title: String, dueDate: Date, completion: @escaping (String?) -> Void)

    /// Update existing calendar event
    func updateEvent(eventIdentifier: String, title: String, dueDate: Date, isPaid: Bool)

    /// Remove calendar event
    func removeEvent(eventIdentifier: String)
}

/// EventKit implementation of CalendarEventDataSource
final class EventKitCalendarDataSource: CalendarEventDataSource {
    private let eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                Task { @MainActor in
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                Task { @MainActor in
                    completion(granted)
                }
            }
        }
    }

    func addEvent(title: String, dueDate: Date, completion: @escaping (String?) -> Void) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = dueDate
        event.endDate = dueDate
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents

        configureAlarms(for: event, dueDate: dueDate)

        do {
            try eventStore.save(event, span: .thisEvent)
            completion(event.eventIdentifier)
        } catch {
            completion(nil)
        }
    }

    func updateEvent(eventIdentifier: String, title: String, dueDate: Date, isPaid: Bool) {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else { return }

        event.title = isPaid ? "✅ \(title)" : title
        event.startDate = dueDate
        event.endDate = dueDate

        // Reconfigure alarms
        if let existingAlarms = event.alarms {
            for alarm in existingAlarms {
                event.removeAlarm(alarm)
            }
        }
        configureAlarms(for: event, dueDate: dueDate)

        try? eventStore.save(event, span: .thisEvent)
    }

    func removeEvent(eventIdentifier: String) {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else { return }
        try? eventStore.remove(event, span: .thisEvent)
    }

    private func configureAlarms(for event: EKEvent, dueDate: Date) {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        dateComponents.hour = 8
        dateComponents.minute = 0
        dateComponents.second = 0

        if let alarmDate = Calendar.current.date(from: dateComponents) {
            let alarm = EKAlarm(absoluteDate: alarmDate)
            event.addAlarm(alarm)
        }
    }
}
