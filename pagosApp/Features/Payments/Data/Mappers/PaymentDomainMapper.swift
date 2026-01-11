//
//  PaymentDomainMapper.swift
//  pagosApp
//
//  Mapper implementation for PaymentLocalDTO ↔ Payment Domain
//  Clean Architecture - Data Layer Mapper Implementation
//

import Foundation

/// Mapper for converting between PaymentLocalDTO (Data) and Payment (Domain)
struct PaymentDomainMapper: PaymentDomainMapping {
    func toDomain(_ dto: PaymentLocalDTO) -> Payment {
        Payment(
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

    func toLocalDTO(_ domain: Payment) -> PaymentLocalDTO {
        PaymentLocalDTO(
            id: domain.id,
            name: domain.name,
            amount: domain.amount,
            currency: domain.currency,
            dueDate: domain.dueDate,
            isPaid: domain.isPaid,
            category: domain.category,
            eventIdentifier: domain.eventIdentifier,
            syncStatus: domain.syncStatus,
            lastSyncedAt: domain.lastSyncedAt,
            groupId: domain.groupId
        )
    }

    func toDomain(_ dtos: [PaymentLocalDTO]) -> [Payment] {
        dtos.map { toDomain($0) }
    }
}
