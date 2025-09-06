import Foundation
import EventKit

class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    private let eventStore = EKEventStore()

    /// Solicita permiso al usuario para acceder al calendario.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents {
                granted, _ in
                DispatchQueue.main.async {
                    // Error al solicitar acceso al calendario
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    // Error al solicitar acceso al calendario
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
            completion(event.eventIdentifier)
        } catch _ as NSError {
            completion(nil)
        }
    }

    /// Actualiza un evento existente en el calendario.
    func updateEvent(for payment: Payment) {
        guard let eventIdentifier = payment.eventIdentifier,
              let event = eventStore.event(withIdentifier: eventIdentifier) else {
            // Si no hay evento (p.ej. se borró manualmente), lo creamos de nuevo si no está pagado.
            if !payment.isPaid {
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
        } catch _ {
            // Error al actualizar evento
        }
    }

    /// Elimina un evento del calendario.
    func removeEvent(for payment: Payment) {
        guard let eventIdentifier = payment.eventIdentifier,
              let event = eventStore.event(withIdentifier: eventIdentifier) else { return }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch _ {
            // Error al eliminar evento
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
        dateComponents.hour = 8 // Changed from 9 to 8
        dateComponents.minute = 0
        dateComponents.second = 0

        if let alarmDate = Calendar.current.date(from: dateComponents) {
            let alarm = EKAlarm(absoluteDate: alarmDate)
            event.addAlarm(alarm)
        }
    }
}