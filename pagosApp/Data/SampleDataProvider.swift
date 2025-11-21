import Foundation

struct SampleDataProvider {
    static func getSampleData() -> [Payment] {
        [
            Payment(name: "Recibo de Luz", amount: 55.70, dueDate: Date().addingTimeInterval(86400 * 2), category: .servicios),
            Payment(name: "Pago Tarjeta Visa", amount: 250.00, dueDate: Date().addingTimeInterval(86400 * 5), category: .tarjetaCredito),
            Payment(name: "Netflix", amount: 15.99, dueDate: Date().addingTimeInterval(86400 * 10), category: .suscripcion),
            Payment(name: "Gimnasio (Mes Pasado)", amount: 45.00, dueDate: Date().addingTimeInterval(-86400 * 25), isPaid: true, category: .otro),
            Payment(name: "Internet (Mes Pasado)", amount: 60.00, dueDate: Date().addingTimeInterval(-86400 * 35), isPaid: true, category: .servicios)
        ]
    }
}
