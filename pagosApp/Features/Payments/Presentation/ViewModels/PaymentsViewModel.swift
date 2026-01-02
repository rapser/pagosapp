import Foundation
import Observation

@MainActor
@Observable
final class PaymentsViewModel {
    // Observable properties automatically notify views when changed
    var payments: [Payment] = []

    init() {
        // Cargamos datos de ejemplo para empezar.
        loadSampleData()
    }

    /// Añade un nuevo pago a la lista y la ordena por fecha.
    func addPayment(name: String, amount: Double, dueDate: Date, category: PaymentCategory) {
        let newPayment = Payment(
            id: UUID(),
            name: name,
            amount: amount,
            currency: .pen,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: nil
        )
        payments.append(newPayment)
        // Ordenamos para que los más próximos aparezcan primero.
        payments.sort { $0.dueDate < $1.dueDate }
    }

    /// Actualiza el estado de un pago (pagado o no pagado).
    func updatePaymentStatus(payment: Payment, isPaid: Bool) {
        if let index = payments.firstIndex(where: { $0.id == payment.id }) {
            let updatedPayment = Payment(
                id: payment.id,
                name: payment.name,
                amount: payment.amount,
                currency: payment.currency,
                dueDate: payment.dueDate,
                isPaid: isPaid,
                category: payment.category,
                eventIdentifier: payment.eventIdentifier,
                syncStatus: payment.syncStatus,
                lastSyncedAt: payment.lastSyncedAt,
                groupId: payment.groupId
            )
            payments[index] = updatedPayment
        }
    }

    /// Devuelve los pagos que corresponden a una fecha específica.
    func getPayments(for date: Date) -> [Payment] {
        let calendar = Calendar.current
        return payments.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func loadSampleData() {
        self.payments = [
            Payment(id: UUID(), name: "Recibo de Luz", amount: 55.70, currency: .pen, dueDate: Date().addingTimeInterval(86400 * 2), isPaid: false, category: .servicios, eventIdentifier: nil, syncStatus: .local, lastSyncedAt: nil, groupId: nil),
            Payment(id: UUID(), name: "Pago Tarjeta Visa", amount: 250.00, currency: .pen, dueDate: Date().addingTimeInterval(86400 * 5), isPaid: false, category: .tarjetaCredito, eventIdentifier: nil, syncStatus: .local, lastSyncedAt: nil, groupId: nil),
            Payment(id: UUID(), name: "Netflix", amount: 15.99, currency: .usd, dueDate: Date().addingTimeInterval(86400 * 10), isPaid: false, category: .suscripcion, eventIdentifier: nil, syncStatus: .local, lastSyncedAt: nil, groupId: nil),
            Payment(id: UUID(), name: "Ahorro Mensual", amount: 300.00, currency: .pen, dueDate: Date().addingTimeInterval(86400 * 1), isPaid: false, category: .servicios, eventIdentifier: nil, syncStatus: .local, lastSyncedAt: nil, groupId: nil)
        ]
        payments.sort { $0.dueDate < $1.dueDate }
    }
}
