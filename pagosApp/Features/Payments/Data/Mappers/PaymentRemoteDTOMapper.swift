//
//  PaymentRemoteDTOMapper.swift
//  pagosApp
//
//  Mapper implementation for PaymentDTO ↔ Payment Domain
//  Clean Architecture - Data Layer Remote Mapper Implementation
//

import Foundation

/// Mapper for converting between PaymentDTO (Remote) and Payment (Domain)
struct PaymentRemoteDTOMapper: PaymentRemoteDTOMapping {
    func toDomain(_ dto: PaymentDTO) -> Payment {
        Payment(
            id: dto.id,
            name: dto.name,
            amount: Decimal(dto.amount),
            currency: Currency(rawValue: dto.currency) ?? .pen,
            dueDate: dto.dueDate,
            isPaid: dto.isPaid,
            category: PaymentCategory(rawValue: dto.category) ?? .otro,
            eventIdentifier: dto.eventIdentifier,
            syncStatus: .synced,
            lastSyncedAt: dto.updatedAt ?? Date(),
            groupId: dto.groupId
        )
    }

    func toRemoteDTO(_ domain: Payment, userId: UUID) -> PaymentDTO {
        PaymentDTO(
            id: domain.id,
            userId: userId,
            name: domain.name,
            amount: NSDecimalNumber(decimal: domain.amount).doubleValue,
            currency: domain.currency.rawValue,
            dueDate: domain.dueDate,
            isPaid: domain.isPaid,
            category: domain.category.rawValue,
            eventIdentifier: domain.eventIdentifier,
            groupId: domain.groupId,
            createdAt: nil,
            updatedAt: domain.lastSyncedAt
        )
    }

    func toDomain(_ dtos: [PaymentDTO]) -> [Payment] {
        dtos.map { toDomain($0) }
    }
}
