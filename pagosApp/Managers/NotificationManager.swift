import Foundation
import UserNotifications
import Observation

@Observable
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Añade la presentación de la notificación en primer plano.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    /// Solicita permiso al usuario para enviar notificaciones.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                // Permiso de notificación concedido.
            } else {
                // Error al solicitar permiso
            }
        }
    }

    /// Programa notificaciones para un pago (2 días antes, 1 día antes y el mismo día).
    /// Si ya existe una, la actualiza. No programa si el pago está marcado como pagado.
    func scheduleNotification(for payment: Payment) {
        // Si el pago ya está marcado como pagado, cancelamos cualquier notificación pendiente y no programamos nuevas.
        guard !payment.isPaid else {
            cancelNotification(for: payment)
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Definir los días antes del vencimiento para notificar
        let notificationDays = [0, 1, 2] // 0: mismo día, 1: un día antes, 2: dos días antes

        for daysBefore in notificationDays {
            guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: payment.dueDate) else { continue }

            // Solo programar si la fecha de notificación es en el futuro o hoy
            if notificationDate >= calendar.startOfDay(for: now) {
                let content = UNMutableNotificationContent()
                content.title = "Recordatorio de Pago"
                
                if daysBefore == 0 {
                    content.subtitle = "¡Hoy vence \(payment.name)!"
                    let formattedAmount = payment.amount.formatted(.number.precision(.fractionLength(2)))
                    content.body = "No olvides pagar \(payment.currency.symbol)\(formattedAmount)."
                } else {
                    content.subtitle = "Vence en \(daysBefore) día(s): \(payment.name)"
                    let formattedAmount = payment.amount.formatted(.number.precision(.fractionLength(2)))
                    content.body = "Recuerda que tienes un pago de \(payment.currency.symbol)\(formattedAmount) pendiente."
                }
                content.sound = .default

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                dateComponents.hour = 9 // Hora de disparo: 9:00 AM
                dateComponents.minute = 0
                dateComponents.second = 0
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let identifier = "\(payment.id.uuidString)-\(daysBefore)days"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { _ in
                    // Notificación programada
                }
            } else {
                // Notificación omitida (fecha pasada).
            }
        }
    }

    /// Cancela todas las notificaciones programadas para un pago.
    func cancelNotification(for payment: Payment) {
        let identifiersToCancel = ["\(payment.id.uuidString)-0days", "\(payment.id.uuidString)-1days", "\(payment.id.uuidString)-2days"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        // Notificaciones canceladas para pago
    }
}