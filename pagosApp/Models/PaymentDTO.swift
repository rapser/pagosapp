//
//  PaymentDTO.swift
//  pagosApp
//
//  Data Transfer Object for syncing with Supabase
//

import Foundation

/// Payment Data Transfer Object for API communication
struct PaymentDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let amount: Double
    let currency: String
    let dueDate: Date
    let isPaid: Bool
    let category: String
    let eventIdentifier: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case currency
        case dueDate = "due_date"
        case isPaid = "is_paid"
        case category
        case eventIdentifier = "event_identifier"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Initialize from local Payment model
    init(from payment: Payment, userId: UUID) {
        self.id = payment.id
        self.userId = userId
        self.name = payment.name
        self.amount = payment.amount
        self.currency = payment.currency.rawValue
        self.dueDate = payment.dueDate
        self.isPaid = payment.isPaid
        self.category = payment.category.rawValue
        self.eventIdentifier = payment.eventIdentifier
        self.createdAt = nil
        self.updatedAt = nil
    }

    /// Initialize from Codable (for API responses)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "PEN" // Default to PEN for backward compatibility

        // Handle date decoding with ISO8601 format
        let dueDateString = try container.decode(String.self, forKey: .dueDate)
        if let date = ISO8601DateFormatter().date(from: dueDateString) {
            dueDate = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .dueDate,
                in: container,
                debugDescription: "Date string does not match expected format"
            )
        }

        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        category = try container.decode(String.self, forKey: .category)
        eventIdentifier = try container.decodeIfPresent(String.self, forKey: .eventIdentifier)

        // Decode timestamps if present
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = ISO8601DateFormatter().date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = nil
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = ISO8601DateFormatter().date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = nil
        }
    }

    /// Convert to local Payment model
    func toPayment() -> Payment {
        let paymentCategory = PaymentCategory(rawValue: category) ?? .otro
        let paymentCurrency = Currency(rawValue: currency) ?? .pen
        return Payment(
            id: id,
            name: name,
            amount: amount,
            currency: paymentCurrency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: paymentCategory,
            eventIdentifier: eventIdentifier,
            syncStatus: .synced,
            lastSyncedAt: Date()
        )
    }
}

// MARK: - Payment Extension

extension Payment {
    /// Convert to DTO for API communication
    func toDTO(userId: UUID) -> PaymentDTO {
        PaymentDTO(from: self, userId: userId)
    }
}
