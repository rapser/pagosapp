import Foundation
import SwiftData

// Enum para categorizar los pagos.
// CaseIterable nos permite listarlos todos fácilmente.
// Identifiable es para que funcione bien en las vistas de SwiftUI.
// Codable es necesario para que SwiftData pueda almacenarlo.
enum PaymentCategory: String, Codable, CaseIterable, Identifiable {
    case recibo = "Recibo"
    case tarjetaCredito = "Tarjeta de Crédito"
    case ahorro = "Ahorro"
    case suscripcion = "Suscripción"
    case otro = "Otro"
    
    var id: String { self.rawValue }
}

// @Model macro transforma esta clase en un modelo de SwiftData.
@Model
final class Payment {
    // Usamos un UUID para identificar de forma única cada pago, útil para notificaciones.
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var dueDate: Date
    var isPaid: Bool
    var category: PaymentCategory
    // Identificador del evento en el calendario del sistema.
    var eventIdentifier: String?
    
    init(name: String, amount: Double, dueDate: Date, isPaid: Bool = false, category: PaymentCategory) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.category = category
        self.eventIdentifier = nil
    }
}