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
/// Supports both async/await (preferred) and callback-based APIs for compatibility
protocol CalendarEventDataSource {
    /// Request calendar access permission (async/await - preferred)
    func requestAccess() async -> Bool
    
    /// Request calendar access permission (callback-based - for compatibility)
    func requestAccess(completion: @escaping (Bool) -> Void)

    /// Add calendar event for a payment (async/await - preferred)
    func addEvent(title: String, dueDate: Date) async -> String?
    
    /// Add calendar event for a payment (callback-based - for compatibility)
    func addEvent(title: String, dueDate: Date, completion: @escaping (String?) -> Void)

    /// Update existing calendar event
    func updateEvent(eventIdentifier: String, title: String, dueDate: Date, isPaid: Bool)

    /// Remove calendar event
    func removeEvent(eventIdentifier: String)
}

/// EventKit implementation of CalendarEventDataSource
final class EventKitCalendarDataSource: CalendarEventDataSource {
    private let eventStore = EKEventStore()

    // MARK: - Async/Await Methods (Preferred)
    
    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func addEvent(title: String, dueDate: Date) async -> String? {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = dueDate
        event.endDate = dueDate
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents

        configureAlarms(for: event, dueDate: dueDate)

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            return nil
        }
    }

    // MARK: - Callback-based Methods (For Compatibility)
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        Task {
            let granted = await requestAccess()
            await MainActor.run {
                completion(granted)
            }
        }
    }

    func addEvent(title: String, dueDate: Date, completion: @escaping (String?) -> Void) {
        Task {
            let identifier = await addEvent(title: title, dueDate: dueDate)
            await MainActor.run {
                completion(identifier)
            }
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
