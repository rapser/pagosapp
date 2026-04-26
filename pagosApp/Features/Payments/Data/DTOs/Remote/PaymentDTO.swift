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
    let groupId: UUID?
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
        case groupId = "group_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Memberwise initializer for creating DTOs
    init(
        id: UUID,
        userId: UUID,
        name: String,
        amount: Double,
        currency: String,
        dueDate: Date,
        isPaid: Bool,
        category: String,
        eventIdentifier: String?,
        groupId: UUID?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.category = category
        self.eventIdentifier = eventIdentifier
        self.groupId = groupId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Initialize from Codable (for API responses)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "PEN"

        // Handle date decoding with multiple format support
        let dueDateString = try container.decode(String.self, forKey: .dueDate)
        guard let date = PaymentDTO.parseDate(from: dueDateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .dueDate,
                in: container,
                debugDescription: "Date string '\(dueDateString)' does not match any expected format"
            )
        }
        dueDate = date

        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        category = try container.decode(String.self, forKey: .category)
        eventIdentifier = try container.decodeIfPresent(String.self, forKey: .eventIdentifier)
        groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)

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

        // Order matters: try more specific patterns before generic ones
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ", // ISO8601 + ms + Z with colon
            "yyyy-MM-dd'T'HH:mm:ss.SSSxx", // ISO8601 + ms + Z without colon
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ", // ISO8601 + Z with colon
            "yyyy-MM-dd HH:mm:ss.SSSxx", // PostgreSQL + fractional + Z
            "yyyy-MM-dd HH:mm:ssxx", // PostgreSQL + Z compact
            "yyyy-MM-dd HH:mm:ssZZZ", // PostgreSQL + Z with colon
            "yyyy-MM-dd HH:mm:ss.SSSZZZ", // PostgreSQL + fractional + Z colon
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ", // ISO8601 + microseconds
            "yyyy-MM-dd'T'HH:mm:ss", // No timezone (T)
            "yyyy-MM-dd HH:mm:ss", // No timezone (space)
            "yyyy-MM-dd" // Date only
        ]

        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleanString) {
                return date
            }
        }

        if let date = ISO8601DateFormatter().date(from: cleanString) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: cleanString)
    }
}
