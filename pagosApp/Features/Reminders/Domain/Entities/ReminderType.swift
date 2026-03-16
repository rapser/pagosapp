//
//  ReminderType.swift
//  pagosApp
//
//  Domain enum for reminder categories (generic, reusable for many particular cases).
//  Clean Architecture: Domain layer - no UI or persistence dependencies.
//

import Foundation

/// Generic type of reminder (for display and filtering).
/// Localized display names via L10n. Covers: card renewal, membership, subscription, cobro, savings, deposit, documents, taxes.
enum ReminderType: String, Sendable, CaseIterable, Codable {
    case cardRenewal    // Tarjeta crédito/débito
    case membership     // Membresía anual, club, etc.
    case subscription   // Suscripción a cortar o renovar
    case pension        // Cobro (p. ej. cobro de pago)
    case savings        // Ahorro
    case deposit        // Depósito
    case documents      // DNI, pasaporte, vencimiento documentos
    case taxes          // Impuestos municipal, anual, etc.
    case maintenance    // Mantenimiento
    case insurance      // Seguros
    case health         // Salud
    case rent           // Alquiler
    case warranty       // Garantía
    case certification  // Certificación
    case other
}

extension ReminderType {
    /// Maps stored raw value (including legacy enum values) to current case for DB migration.
    static func from(storedRawValue: String) -> ReminderType {
        if let value = ReminderType(rawValue: storedRawValue) { return value }
        switch storedRawValue {
        case "creditCardRenewal", "debitCardRenewal": return .cardRenewal
        case "annualMembership": return .membership
        case "subscriptionToCancel": return .subscription
        case "collectPayment": return .pension
        case "idExpiration", "passportRenewal": return .documents
        case "municipalTaxes", "annualTaxes": return .taxes
        default: return .other
        }
    }
}
