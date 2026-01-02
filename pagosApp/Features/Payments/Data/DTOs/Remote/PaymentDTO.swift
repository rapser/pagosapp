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

    /// Initialize from local PaymentEntity model
    init(from entity: PaymentEntity, userId: UUID) {
        self.id = entity.id
        self.userId = userId
        self.name = entity.name
        self.amount = entity.amount
        self.currency = entity.currency.rawValue
        self.dueDate = entity.dueDate
        self.isPaid = entity.isPaid
        self.category = entity.category.rawValue
        self.eventIdentifier = entity.eventIdentifier
        self.groupId = entity.groupId
        self.createdAt = nil
        self.updatedAt = nil
    }

    /// Initialize from Codable (for API responses)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            id = try container.decode(UUID.self, forKey: .id)
            print("✅ Decoded id: \(id)")
        } catch {
            print("❌ Failed to decode 'id': \(error)")
            throw error
        }

        do {
            userId = try container.decode(UUID.self, forKey: .userId)
            print("✅ Decoded userId: \(userId)")
        } catch {
            print("❌ Failed to decode 'user_id': \(error)")
            throw error
        }

        do {
            name = try container.decode(String.self, forKey: .name)
            print("✅ Decoded name: \(name)")
        } catch {
            print("❌ Failed to decode 'name': \(error)")
            throw error
        }

        do {
            amount = try container.decode(Double.self, forKey: .amount)
            print("✅ Decoded amount: \(amount)")
        } catch {
            print("❌ Failed to decode 'amount': \(error)")
            throw error
        }

        do {
            currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "PEN"
            print("✅ Decoded currency: \(currency)")
        } catch {
            print("❌ Failed to decode 'currency': \(error)")
            throw error
        }

        // Handle date decoding with multiple format support
        do {
            let dueDateString = try container.decode(String.self, forKey: .dueDate)
            print("🔍 Raw due_date string from Supabase: '\(dueDateString)'")

            guard let date = PaymentDTO.parseDate(from: dueDateString) else {
                print("❌ Failed to parse due_date string: '\(dueDateString)'")
                throw DecodingError.dataCorruptedError(
                    forKey: .dueDate,
                    in: container,
                    debugDescription: "Date string '\(dueDateString)' does not match any expected format"
                )
            }
            dueDate = date
            print("✅ Decoded dueDate: \(date)")
        } catch {
            print("❌ Failed to decode 'due_date': \(error)")
            throw error
        }

        do {
            isPaid = try container.decode(Bool.self, forKey: .isPaid)
            print("✅ Decoded isPaid: \(isPaid)")
        } catch {
            print("❌ Failed to decode 'is_paid': \(error)")
            throw error
        }

        do {
            category = try container.decode(String.self, forKey: .category)
            print("✅ Decoded category: \(category)")
        } catch {
            print("❌ Failed to decode 'category': \(error)")
            throw error
        }

        do {
            eventIdentifier = try container.decodeIfPresent(String.self, forKey: .eventIdentifier)
            print("✅ Decoded eventIdentifier: \(eventIdentifier ?? "nil")")
        } catch {
            print("❌ Failed to decode 'event_identifier': \(error)")
            throw error
        }

        do {
            groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
            print("✅ Decoded groupId: \(groupId?.uuidString ?? "nil")")
        } catch {
            print("❌ Failed to decode 'group_id': \(error)")
            throw error
        }

        // Decode timestamps if present
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            print("🔍 Raw created_at string: '\(createdAtString)'")
            createdAt = PaymentDTO.parseDate(from: createdAtString)
            if createdAt != nil {
                print("✅ Decoded createdAt: \(createdAt!)")
            } else {
                print("⚠️ Failed to parse created_at: '\(createdAtString)'")
            }
        } else {
            createdAt = nil
            print("✅ createdAt is nil")
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            print("🔍 Raw updated_at string: '\(updatedAtString)'")
            updatedAt = PaymentDTO.parseDate(from: updatedAtString)
            if updatedAt != nil {
                print("✅ Decoded updatedAt: \(updatedAt!)")
            } else {
                print("⚠️ Failed to parse updated_at: '\(updatedAtString)'")
            }
        } else {
            updatedAt = nil
            print("✅ updatedAt is nil")
        }

        print("✅ Successfully decoded payment: \(name)")
    }

    /// Parse date from string with multiple format support
    private static func parseDate(from dateString: String) -> Date? {
        // Clean the string first (remove potential invisible characters)
        let cleanString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        // ISO8601 with milliseconds (3 digits) and timezone with colon
        // Format: "2026-01-02T20:59:38.015+00:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // ISO8601 with milliseconds and timezone without colon
        // Format: "2026-01-02T20:59:38.015+00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxx"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // ISO8601 without fractional seconds with timezone colon
        // Format: "2025-11-30T17:05:00+00:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // PostgreSQL timestamp with fractional seconds and timezone (no T separator)
        // Format: "2026-01-02 20:59:38.015+00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSxx"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // PostgreSQL timestamp with timezone (no fractional seconds)
        // Format: "2026-01-30 21:01:00+00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssxx"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // PostgreSQL timestamp with timezone colon format
        // Format: "2025-12-12 20:27:00+00:00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // PostgreSQL timestamp with fractional seconds and timezone colon format
        // Format: "2025-12-03 20:30:48.731+00:00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try ISO8601 with microseconds (6 digits)
        // Format: "2025-11-15T17:15:12.926568+00:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        if let date = formatter.date(from: cleanString) {
            return date
        }

        // Try ISO8601 formatter (handles various ISO formats)
        if let date = ISO8601DateFormatter().date(from: cleanString) {
            return date
        }

        // Try ISO8601 without fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: cleanString) {
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

    /// Convert to local PaymentEntity model
    func toEntity() -> PaymentEntity {
        let paymentCategory = PaymentCategory(rawValue: category) ?? .otro
        let paymentCurrency = Currency(rawValue: currency) ?? .pen
        return PaymentEntity(
            id: id,
            name: name,
            amount: amount,
            currency: paymentCurrency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: paymentCategory,
            eventIdentifier: eventIdentifier,
            syncStatus: .synced,
            lastSyncedAt: Date(),
            groupId: groupId
        )
    }
}

// MARK: - PaymentEntity Extension

extension PaymentEntity {
    /// Convert to DTO for API communication
    func toDTO(userId: UUID) -> PaymentDTO {
        PaymentDTO(from: self, userId: userId)
    }
}
