//
//  ReminderDTO.swift
//  pagosApp
//
//  Data Transfer Object for reminder sync with Supabase.
//

import Foundation

/// Remote DTO for reminders table in Supabase
struct ReminderDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let reminderType: String
    let title: String
    let reminderDescription: String
    let dueDate: Date
    let isCompleted: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case reminderType = "reminder_type"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
        case reminderDescription = "description"
        case isCompleted = "is_completed"
    }

    init(id: UUID, userId: UUID, reminderType: String, title: String, reminderDescription: String = "", dueDate: Date, isCompleted: Bool = false, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.userId = userId
        self.reminderType = reminderType
        self.title = title
        self.reminderDescription = reminderDescription
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        reminderType = try container.decode(String.self, forKey: .reminderType)
        title = try container.decode(String.self, forKey: .title)
        reminderDescription = try container.decodeIfPresent(String.self, forKey: .reminderDescription) ?? ""
        dueDate = try ReminderDTO.decodeDate(from: container, forKey: .dueDate)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try ReminderDTO.decodeOptionalDate(from: container, forKey: .createdAt)
        updatedAt = try ReminderDTO.decodeOptionalDate(from: container, forKey: .updatedAt)
    }

    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        if let date = try container.decodeIfPresent(Date.self, forKey: key) { return date }
        let str = try container.decode(String.self, forKey: key)
        guard let date = ReminderDTO.parseDate(from: str) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Invalid date: \(str)")
        }
        return date
    }

    private static func decodeOptionalDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        if let date = try container.decodeIfPresent(Date.self, forKey: key) { return date }
        guard let str = try container.decodeIfPresent(String.self, forKey: key) else { return nil }
        return ReminderDTO.parseDate(from: str)
    }

    private static func parseDate(from dateString: String) -> Date? {
        let clean = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSxx",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd HH:mm:ss.SSSxx",
            "yyyy-MM-dd HH:mm:ssZZZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ] {
            formatter.dateFormat = format
            if let d = formatter.date(from: clean) { return d }
        }
        return ISO8601DateFormatter().date(from: clean)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(reminderType, forKey: .reminderType)
        try container.encode(title, forKey: .title)
        try container.encode(reminderDescription, forKey: .reminderDescription)
        try container.encode(ReminderDTO.iso8601String(from: dueDate), forKey: .dueDate)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(createdAt.map { ReminderDTO.iso8601String(from: $0) }, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt.map { ReminderDTO.iso8601String(from: $0) }, forKey: .updatedAt)
    }

    private static func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
