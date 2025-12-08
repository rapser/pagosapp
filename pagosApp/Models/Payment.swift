import Foundation
import SwiftData

// Enum para categorizar los pagos.
// CaseIterable nos permite listarlos todos fácilmente.
// Identifiable es para que funcione bien en las vistas de SwiftUI.
// Codable es necesario para que SwiftData pueda almacenarlo.
enum PaymentCategory: String, Codable, CaseIterable, Identifiable {
    case servicios = "Servicios"
    case tarjetaCredito = "Tarjeta de Crédito"
    case vivienda = "Vivienda"
    case prestamo = "Préstamo"
    case seguro = "Seguro"
    case educacion = "Educación"
    case impuestos = "Impuestos"
    case suscripcion = "Suscripción"
    case otro = "Otro"

    var id: String { self.rawValue }
}

// Enum para la moneda del pago
enum Currency: String, Codable, CaseIterable, Identifiable {
    case pen = "PEN" // Soles peruanos
    case usd = "USD" // Dólares americanos
    
    var id: String { self.rawValue }
    
    var symbol: String {
        switch self {
        case .pen: return "S/"
        case .usd: return "$"
        }
    }
    
    var displayName: String {
        switch self {
        case .pen: return "Soles (S/)"
        case .usd: return "Dólares ($)"
        }
    }
}

// Estado de sincronización del pago con el servidor
enum SyncStatus: String, Codable {
    case local      // Solo existe localmente, nunca sincronizado
    case syncing    // En proceso de sincronización
    case synced     // Sincronizado correctamente con Supabase
    case modified   // Existe en Supabase pero fue modificado localmente
    case error      // Falló al sincronizar
}

/// SwiftData model representing a payment
/// SwiftData manages thread-safety internally through ModelContext.
/// All access must go through ModelContext on @MainActor.
/// For thread-safe operations, use PaymentEntity instead.
@Model
final class Payment {
    // Usamos un UUID para identificar de forma única cada pago, útil para notificaciones.
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var currency: Currency
    var dueDate: Date
    var isPaid: Bool
    var category: PaymentCategory
    // Identificador del evento en el calendario del sistema.
    var eventIdentifier: String?
    // Estado de sincronización con Supabase
    var syncStatus: SyncStatus
    // Última fecha de sincronización exitosa
    var lastSyncedAt: Date?

    init(name: String, amount: Double, dueDate: Date, isPaid: Bool = false, category: PaymentCategory, currency: Currency = .pen) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.category = category
        self.eventIdentifier = nil
        self.syncStatus = .local
        self.lastSyncedAt = nil
    }

    /// Full initializer for syncing with backend
    init(id: UUID, name: String, amount: Double, currency: Currency = .pen, dueDate: Date, isPaid: Bool, category: PaymentCategory, eventIdentifier: String?, syncStatus: SyncStatus = .local, lastSyncedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.category = category
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
    }
}