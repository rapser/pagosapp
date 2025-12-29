
import Foundation
import SwiftData

@Model
final class Payment {
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
