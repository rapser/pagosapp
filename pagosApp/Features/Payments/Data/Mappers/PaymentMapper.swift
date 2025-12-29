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

    // MARK: - SwiftData Model → Domain Entity

    /// Convert from SwiftData model to domain entity
    static func toDomain(from model: Payment) -> PaymentEntity {
        return PaymentEntity(
            id: model.id,
            name: model.name,
            amount: model.amount,
            currency: model.currency,
            dueDate: model.dueDate,
            isPaid: model.isPaid,
            category: model.category,
            eventIdentifier: model.eventIdentifier,
            syncStatus: model.syncStatus,
            lastSyncedAt: model.lastSyncedAt
        )
    }

    /// Alias for toDomain - clearer naming
    static func toEntity(from model: Payment) -> PaymentEntity {
        return toDomain(from: model)
    }

    /// Convert array of models to domain entities
    static func toDomain(from models: [Payment]) -> [PaymentEntity] {
        return models.map { toDomain(from: $0) }
    }

    /// Alias for array conversion
    static func toEntity(from models: [Payment]) -> [PaymentEntity] {
        return toDomain(from: models)
    }

    // MARK: - Domain Entity → SwiftData Model

    /// Convert from domain entity to SwiftData model
    static func toModel(from entity: PaymentEntity) -> Payment {
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
            lastSyncedAt: entity.lastSyncedAt
        )
    }

    /// Convert array of entities to models
    static func toModel(from entities: [PaymentEntity]) -> [Payment] {
        return entities.map { toModel(from: $0) }
    }

    // MARK: - Remote DTO → Domain Entity

    /// Convert from remote DTO to domain entity
    static func toDomain(from dto: PaymentDTO) -> PaymentEntity {
        let paymentCategory = PaymentCategory(rawValue: dto.category) ?? .otro
        let paymentCurrency = Currency(rawValue: dto.currency) ?? .pen

        return PaymentEntity(
            id: dto.id,
            name: dto.name,
            amount: dto.amount,
            currency: paymentCurrency,
            dueDate: dto.dueDate,
            isPaid: dto.isPaid,
            category: paymentCategory,
            eventIdentifier: dto.eventIdentifier,
            syncStatus: .synced, // Remote payments are always synced
            lastSyncedAt: Date()
        )
    }

    /// Convert array of remote DTOs to domain entities
    static func toDomain(from dtos: [PaymentDTO]) -> [PaymentEntity] {
        return dtos.map { toDomain(from: $0) }
    }

    // MARK: - Domain Entity → Remote DTO

    /// Convert from domain entity to remote DTO
    static func toRemoteDTO(from entity: PaymentEntity, userId: UUID) -> PaymentDTO {
        // First convert to SwiftData model, then to DTO
        let payment = toModel(from: entity)
        return PaymentDTO(from: payment, userId: userId)
    }

    /// Convert array of entities to remote DTOs
    static func toRemoteDTO(from entities: [PaymentEntity], userId: UUID) -> [PaymentDTO] {
        return entities.map { toRemoteDTO(from: $0, userId: userId) }
    }
}
