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

    // MARK: - SwiftData DTO → Domain

    /// Convert from SwiftData DTO to domain
    static func toDomain(from dto: PaymentLocalDTO) -> Payment {
        return Payment(
            id: dto.id,
            name: dto.name,
            amount: dto.amount,
            currency: dto.currency,
            dueDate: dto.dueDate,
            isPaid: dto.isPaid,
            category: dto.category,
            eventIdentifier: dto.eventIdentifier,
            syncStatus: dto.syncStatus,
            lastSyncedAt: dto.lastSyncedAt,
            groupId: dto.groupId
        )
    }

    /// Convert array of DTOs to domain
    static func toDomain(from dtos: [PaymentLocalDTO]) -> [Payment] {
        return dtos.map { toDomain(from: $0) }
    }

    // MARK: - Domain → SwiftData DTO

    /// Convert from domain to SwiftData DTO
    static func toLocalDTO(from payment: Payment) -> PaymentLocalDTO {
        return PaymentLocalDTO(
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

    /// Convert array of domain to DTOs
    static func toLocalDTO(from payments: [Payment]) -> [PaymentLocalDTO] {
        return payments.map { toLocalDTO(from: $0) }
    }

    // MARK: - Remote DTO → Domain

    /// Convert from remote DTO to domain
    static func toDomain(from dto: PaymentDTO) -> Payment {
        let paymentCategory = PaymentCategory(rawValue: dto.category) ?? .otro
        let paymentCurrency = Currency(rawValue: dto.currency) ?? .pen

        return Payment(
            id: dto.id,
            name: dto.name,
            amount: Decimal(dto.amount),  // Convert Double to Decimal
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
    static func toRemoteDTO(from payment: Payment, userId: UUID) -> PaymentDTO {
        return PaymentDTO(
            id: payment.id,
            userId: userId,
            name: payment.name,
            amount: NSDecimalNumber(decimal: payment.amount).doubleValue,
            currency: payment.currency.rawValue,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category.rawValue,
            eventIdentifier: payment.eventIdentifier,
            groupId: payment.groupId,
            createdAt: nil,
            updatedAt: payment.lastSyncedAt
        )
    }

    /// Convert array of domain to remote DTOs
    static func toRemoteDTO(from payments: [Payment], userId: UUID) -> [PaymentDTO] {
        return payments.map { toRemoteDTO(from: $0, userId: userId) }
    }
}
