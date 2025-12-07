import Foundation
import EventKit
import Observation
import OSLog

@MainActor
@Observable
final class EventKitManager {
    static let shared = EventKitManager()
    private let eventStore = EKEventStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "EventKit")

    /// Solicita permiso al usuario para acceder al calendario.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor [weak self] in
                    if let error = error {
                        self?.logger.error("❌ Error requesting calendar access: \(error.localizedDescription)")
                    }
                    if granted {
                        self?.logger.info("✅ Calendar access granted")
                    } else {
                        self?.logger.info("⚠️ Calendar access denied")
                    }
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor [weak self] in
                    if let error = error {
                        self?.logger.error("❌ Error requesting calendar access: \(error.localizedDescription)")
                    }
                    if granted {
                        self?.logger.info("✅ Calendar access granted")
                    } else {
                        self?.logger.info("⚠️ Calendar access denied")
                    }
                    completion(granted)
                }
            }
        }
    }

    /// Añade un evento al calendario para un pago y devuelve el ID del evento.
    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Pago: \(payment.name)"
        event.startDate = payment.dueDate
        event.endDate = payment.dueDate
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents

        configureAlarms(for: event, dueDate: payment.dueDate)

        do {
            try eventStore.save(event, span: .thisEvent)
            logger.info("✅ Calendar event created for payment: \(payment.name)")
            completion(event.eventIdentifier)
        } catch {
            logger.error("❌ Failed to save calendar event: \(error.localizedDescription)")
            Task { @MainActor in
                ErrorHandler.shared.handle(PaymentError.calendarSyncFailed(error))
            }
            completion(nil)
        }
    }

    /// Actualiza un evento existente en el calendario.
    func updateEvent(for payment: Payment) {
        guard let eventIdentifier = payment.eventIdentifier,
              let event = eventStore.event(withIdentifier: eventIdentifier) else {
            // Si no hay evento (p.ej. se borró manualmente), lo creamos de nuevo si no está pagado.
            logger.warning("⚠️ Event not found for payment: \(payment.name)")
            if !payment.isPaid {
                logger.info("Creating new calendar event for unpaid payment: \(payment.name)")
                addEvent(for: payment) { newIdentifier in
                    payment.eventIdentifier = newIdentifier
                }
            }
            return
        }

        event.title = payment.isPaid ? "✅ Pago: \(payment.name)" : "Pago: \(payment.name)"
        event.startDate = payment.dueDate
        event.endDate = payment.dueDate

        // Remove existing alarms and reconfigure
        if let existingAlarms = event.alarms {
            for alarm in existingAlarms {
                event.removeAlarm(alarm)
            }
        }
        configureAlarms(for: event, dueDate: payment.dueDate)

        do {
            try eventStore.save(event, span: .thisEvent)
            logger.info("✅ Calendar event updated for payment: \(payment.name)")
        } catch {
            logger.error("❌ Failed to update calendar event: \(error.localizedDescription)")
            Task { @MainActor in
                ErrorHandler.shared.handle(PaymentError.calendarSyncFailed(error))
            }
        }
    }

    /// Elimina un evento del calendario.
    func removeEvent(for payment: Payment) {
        guard let eventIdentifier = payment.eventIdentifier,
              let event = eventStore.event(withIdentifier: eventIdentifier) else {
            logger.warning("⚠️ No event to remove for payment: \(payment.name)")
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            logger.info("✅ Calendar event removed for payment: \(payment.name)")
        } catch {
            logger.error("❌ Failed to remove calendar event: \(error.localizedDescription)")
            Task { @MainActor in
                ErrorHandler.shared.handle(PaymentError.calendarSyncFailed(error))
            }
        }
    }
    
    private func configureAlarms(for event: EKEvent, dueDate: Date) {
        // Clear existing alarms to avoid duplicates if updating
        if let existingAlarms = event.alarms {
            for alarm in existingAlarms {
                event.removeAlarm(alarm)
            }
        }

        // Set alarm for 8:00 AM on the due date
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
