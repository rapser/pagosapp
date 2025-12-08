import Foundation

struct SampleDataProvider {
    static func getSampleData() -> [Payment] {
        [
            Payment(name: "Recibo de Luz", amount: 55.70, dueDate: Date().addingTimeInterval(86400 * 2), category: .servicios, currency: .pen),
            Payment(name: "Pago Tarjeta Visa", amount: 250.00, dueDate: Date().addingTimeInterval(86400 * 5), category: .tarjetaCredito, currency: .pen),
            Payment(name: "Netflix", amount: 15.99, dueDate: Date().addingTimeInterval(86400 * 10), category: .suscripcion, currency: .usd),
            Payment(name: "Gimnasio (Mes Pasado)", amount: 45.00, dueDate: Date().addingTimeInterval(-86400 * 25), isPaid: true, category: .otro, currency: .pen),
            Payment(name: "Internet (Mes Pasado)", amount: 60.00, dueDate: Date().addingTimeInterval(-86400 * 35), isPaid: true, category: .servicios, currency: .pen),
            Payment(name: "Amazon Prime", amount: 12.99, dueDate: Date().addingTimeInterval(86400 * 7), category: .suscripcion, currency: .usd)
        ]
    }
}
