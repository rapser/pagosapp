//
//  CreditCardMapper.swift
//  pagosApp
//
//  Maps between CreditCardLocalDTO (SwiftData) and CreditCard (Domain)
//  Clean Architecture - Data Layer
//
//  Sensitive fields (full number, PIN) never cross this mapper - they live only
//  in Keychain, handled separately by KeychainCreditCardDataSource.
//

import Foundation

enum CreditCardMapper {
    static func toDomain(from dto: CreditCardLocalDTO) -> CreditCard {
        CreditCard(
            id: dto.id,
            bank: dto.bank,
            customBankName: dto.customBankName,
            brand: dto.brand,
            last4: dto.last4,
            expirationMonth: dto.expirationMonth,
            expirationYear: dto.expirationYear,
            createdAt: dto.createdAt
        )
    }

    static func toLocalDTO(from card: CreditCard) -> CreditCardLocalDTO {
        CreditCardLocalDTO(
            id: card.id,
            bank: card.bank,
            customBankName: card.customBankName,
            brand: card.brand,
            last4: card.last4,
            expirationMonth: card.expirationMonth,
            expirationYear: card.expirationYear,
            createdAt: card.createdAt
        )
    }
}
