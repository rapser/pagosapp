//
//  PaymentRemoteDTOMapping.swift
//  pagosApp
//
//  Protocol for mapping between PaymentDTO (Remote Data) and Payment (Domain)
//  Clean Architecture - Data Layer Remote Mapper Protocol
//

import Foundation

/// Protocol for mapping between PaymentDTO (Remote) and Payment (Domain)
/// SOLID: Dependency Inversion Principle - depend on abstractions
protocol PaymentRemoteDTOMapping: Sendable {
    /// Convert from Remote DTO to Domain
    func toDomain(_ dto: PaymentDTO) -> Payment

    /// Convert from Domain to Remote DTO (requires userId)
    func toRemoteDTO(_ domain: Payment, userId: UUID) -> PaymentDTO

    /// Convert array from Remote DTO to Domain
    func toDomain(_ dtos: [PaymentDTO]) -> [Payment]
}
