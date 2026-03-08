//
//  ReminderType.swift
//  pagosApp
//
//  Domain enum for reminder categories.
//  Clean Architecture: Domain layer - no UI or persistence dependencies.
//

import Foundation

/// Type of reminder (for display and filtering).
/// Localized display names via L10n.
enum ReminderType: String, Sendable, CaseIterable, Codable {
    case creditCardRenewal
    case debitCardRenewal
    case annualMembership
    case subscriptionToCancel
    case collectPayment
    case idExpiration
    case passportRenewal
    case municipalTaxes
    case annualTaxes
    case other
}
