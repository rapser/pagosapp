//
//  PaymentDomainMapping.swift
//  pagosApp
//
//  Protocol for mapping between PaymentLocalDTO (Data) and Payment (Domain)
//  Clean Architecture - Data Layer Mapper Protocol
//

import Foundation

/// Protocol for mapping between PaymentLocalDTO (Data) and Payment (Domain)
/// SOLID: Dependency Inversion Principle - depend on abstractions
protocol PaymentDomainMapping: Sendable {
    /// Convert from Local DTO to Domain
    func toDomain(_ dto: PaymentLocalDTO) -> Payment

    /// Convert from Domain to Local DTO
    func toLocalDTO(_ domain: Payment) -> PaymentLocalDTO

    /// Convert array from Local DTO to Domain
    func toDomain(_ dtos: [PaymentLocalDTO]) -> [Payment]
}
