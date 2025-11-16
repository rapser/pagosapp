import Foundation
import Combine

class PaymentsViewModel: ObservableObject {
    // @Published notifica a las vistas cuando la lista de pagos cambia.
    @Published var payments: [Payment] = []

    init() {
        // Cargamos datos de ejemplo para empezar.
        loadSampleData()
    }

    /// Añade un nuevo pago a la lista y la ordena por fecha.
    func addPayment(name: String, amount: Double, dueDate: Date, category: PaymentCategory) {
        let newPayment = Payment(name: name, amount: amount, dueDate: dueDate, category: category)
        payments.append(newPayment)
        // Ordenamos para que los más próximos aparezcan primero.
        payments.sort { $0.dueDate < $1.dueDate }
    }

    /// Actualiza el estado de un pago (pagado o no pagado).
    func updatePaymentStatus(payment: Payment, isPaid: Bool) {
        if let index = payments.firstIndex(where: { $0.id == payment.id }) {
            payments[index].isPaid = isPaid
        }
    }
    
    /// Devuelve los pagos que corresponden a una fecha específica.
    func getPayments(for date: Date) -> [Payment] {
        let calendar = Calendar.current
        return payments.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func loadSampleData() {
        self.payments = [
            Payment(name: "Recibo de Luz", amount: 55.70, dueDate: Date().addingTimeInterval(86400 * 2), category: .servicios),
            Payment(name: "Pago Tarjeta Visa", amount: 250.00, dueDate: Date().addingTimeInterval(86400 * 5), category: .tarjetaCredito),
            Payment(name: "Netflix", amount: 15.99, dueDate: Date().addingTimeInterval(86400 * 10), category: .suscripcion),
            Payment(name: "Ahorro Mensual", amount: 300.00, dueDate: Date().addingTimeInterval(86400 * 1), category: .servicios)
        ]
        payments.sort { $0.dueDate < $1.dueDate }
    }
}
