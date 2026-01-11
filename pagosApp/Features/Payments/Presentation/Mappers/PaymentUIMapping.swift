//
//  PaymentUIMapping.swift
//  pagosApp
//
//  Protocol for mapping between Payment (Domain) and PaymentUI (Presentation)
//  Clean Architecture - Presentation Layer Mapper Protocol
//

import Foundation

/// Protocol for mapping between Payment (Domain) and PaymentUI (Presentation)
/// SOLID: Dependency Inversion Principle - depend on abstractions, not concretions
protocol PaymentUIMapping: Sendable {
    /// Convert from Domain to Presentation
    func toUI(_ domain: Payment) -> PaymentUI

    /// Convert from Presentation to Domain
    func toDomain(_ ui: PaymentUI) -> Payment

    /// Convert array from Domain to Presentation
    func toUI(_ domains: [Payment]) -> [PaymentUI]

    /// Convert array from Presentation to Domain
    func toDomain(_ uis: [PaymentUI]) -> [Payment]
}
