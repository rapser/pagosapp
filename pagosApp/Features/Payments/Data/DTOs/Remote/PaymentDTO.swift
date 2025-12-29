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

        // Handle date decoding with multiple format support
        let dueDateString = try container.decode(String.self, forKey: .dueDate)
        guard let date = PaymentDTO.parseDate(from: dueDateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .dueDate,
                in: container,
                debugDescription: "Date string does not match expected format"
            )
        }
        dueDate = date

        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        category = try container.decode(String.self, forKey: .category)
        eventIdentifier = try container.decodeIfPresent(String.self, forKey: .eventIdentifier)

        // Decode timestamps if present
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = PaymentDTO.parseDate(from: createdAtString)
        } else {
            createdAt = nil
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = PaymentDTO.parseDate(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }

    /// Parse date from string with multiple format support
    private static func parseDate(from dateString: String) -> Date? {
        // Clean the string first (remove potential invisible characters)
        let cleanString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        // PostgreSQL timestamp with timezone (most common in Supabase)
        // Format: "2025-12-12 20:27:00+00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // PostgreSQL timestamp with fractional seconds and timezone
        // Format: "2025-12-03 20:30:48.731+00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try ISO8601 first (most common)
        if let date = ISO8601DateFormatter().date(from: cleanString) {
            return date
        }

        // Try ISO8601 without fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: cleanString) {
            return date
        }

        // Try RFC3339 (similar to ISO8601 but more flexible)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try without timezone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try without timezone (PostgreSQL style)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try date only format
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        return nil
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
