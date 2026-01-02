//
//  PaymentMapper.swift
//  pagosApp
//
//  Mapper for converting between Payment DTOs and Domain Entities
//  Clean Architecture - Data Layer
//

import Foundation

/// Mapper for Payment conversions between layers
struct PaymentMapper {

    // MARK: - SwiftData Entity → Domain

    /// Convert from SwiftData entity to domain
    static func toDomain(from entity: PaymentEntity) -> Payment {
        return Payment(
            id: entity.id,
            name: entity.name,
            amount: entity.amount,
            currency: entity.currency,
            dueDate: entity.dueDate,
            isPaid: entity.isPaid,
            category: entity.category,
            eventIdentifier: entity.eventIdentifier,
            syncStatus: entity.syncStatus,
            lastSyncedAt: entity.lastSyncedAt,
            groupId: entity.groupId
        )
    }

    /// Convert array of entities to domain
    static func toDomain(from entities: [PaymentEntity]) -> [Payment] {
        return entities.map { toDomain(from: $0) }
    }

    // MARK: - Domain → SwiftData Entity

    /// Convert from domain to SwiftData entity
    static func toEntity(from payment: Payment) -> PaymentEntity {
        return PaymentEntity(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: payment.eventIdentifier,
            syncStatus: payment.syncStatus,
            lastSyncedAt: payment.lastSyncedAt,
            groupId: payment.groupId
        )
    }

    /// Convert array of domain to entities
    static func toEntity(from payments: [Payment]) -> [PaymentEntity] {
        return payments.map { toEntity(from: $0) }
    }

    // MARK: - Remote DTO → Domain

    /// Convert from remote DTO to domain
    static func toDomain(from dto: PaymentDTO) -> Payment {
        let paymentCategory = PaymentCategory(rawValue: dto.category) ?? .otro
        let paymentCurrency = Currency(rawValue: dto.currency) ?? .pen

        return Payment(
            id: dto.id,
            name: dto.name,
            amount: dto.amount,
            currency: paymentCurrency,
            dueDate: dto.dueDate,
            isPaid: dto.isPaid,
            category: paymentCategory,
            eventIdentifier: dto.eventIdentifier,
            syncStatus: .synced, // Remote payments are always synced
            lastSyncedAt: Date(),
            groupId: dto.groupId
        )
    }

    /// Convert array of remote DTOs to domain
    static func toDomain(from dtos: [PaymentDTO]) -> [Payment] {
        return dtos.map { toDomain(from: $0) }
    }

    // MARK: - Domain → Remote DTO

    /// Convert from domain to remote DTO
    static func toDTO(from payment: Payment, userId: UUID) -> PaymentDTO {
        // First convert to SwiftData entity, then to DTO
        let entity = toEntity(from: payment)
        return PaymentDTO(from: entity, userId: userId)
    }

    /// Convert array of domain to remote DTOs
    static func toDTO(from payments: [Payment], userId: UUID) -> [PaymentDTO] {
        return payments.map { toDTO(from: $0, userId: userId) }
    }
}
