//
//  LocalNotificationIdentifiers.swift
//  pagosApp
//
//  Single source of truth for local notification request identifiers
//  (payment- / reminder- prefixes + legacy unprefixed payment IDs).
//

import Foundation

enum LocalNotificationEntityKind {
    case payment
    case reminder

    fileprivate var idPrefix: String {
        switch self {
        case .payment: return "payment"
        case .reminder: return "reminder"
        }
    }
}

enum LocalNotificationIdentifiers {
    /// All day offsets the reminder feature may have scheduled historically or today.
    enum ReminderOffsetCatalog {
        static let allPossibleCancellationOffsets: [Int] = [30, 14, 7, 5, 4, 3, 2, 1, 0]
    }

    /// Matches fixed schedule in `UserNotificationsDataSource.scheduleNotifications` for payments.
    static let paymentStandardNotificationDays: [Int] = [3, 2, 1, 0]

    static func identifier(
        kind: LocalNotificationEntityKind,
        entityId: UUID,
        daysUntilDue: Int,
        timeOfDay: TimeOfDay?
    ) -> String {
        let head = "\(kind.idPrefix)-\(entityId.uuidString)"
        if daysUntilDue == 0, let timeOfDay {
            return "\(head)-0days-\(timeOfDay.suffix)"
        }
        return "\(head)-\(daysUntilDue)days"
    }

    /// Same (daysBefore, timeOfDay) matrix as `GenericNotificationScheduler.scheduleNotifications`.
    static func allScheduledIdentifiers(
        kind: LocalNotificationEntityKind,
        entityId: UUID,
        notificationDays: [Int]
    ) -> [String] {
        var ids: [String] = []
        for daysBefore in notificationDays {
            if daysBefore == 0 {
                for timeOfDay in TimeOfDay.allCases {
                    ids.append(identifier(kind: kind, entityId: entityId, daysUntilDue: 0, timeOfDay: timeOfDay))
                }
            } else {
                ids.append(identifier(kind: kind, entityId: entityId, daysUntilDue: daysBefore, timeOfDay: .morning))
            }
        }
        return ids
    }

    /// Pre-migration payment identifiers (no `payment-` prefix), kept for cancellation after upgrade.
    static func legacyPaymentIdentifiersWithoutPrefix(entityId: UUID) -> [String] {
        let u = entityId.uuidString
        return [
            "\(u)-0days-9am",
            "\(u)-0days-2pm",
            "\(u)-1days",
            "\(u)-2days",
            "\(u)-3days",
            "\(u)-0days",
            "\(u)-0days-immediate"
        ]
    }

    static func allPaymentCancellationIdentifiers(entityId: UUID) -> [String] {
        let modern = allScheduledIdentifiers(
            kind: .payment,
            entityId: entityId,
            notificationDays: paymentStandardNotificationDays
        )
        let legacy = legacyPaymentIdentifiersWithoutPrefix(entityId: entityId)
        return Array(Set(modern + legacy))
    }

    static func allReminderCancellationIdentifiers(entityId: UUID) -> [String] {
        allScheduledIdentifiers(
            kind: .reminder,
            entityId: entityId,
            notificationDays: ReminderOffsetCatalog.allPossibleCancellationOffsets
        )
    }

    static func isReminderNotificationIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix("reminder-")
    }

    static func isPaymentNotificationIdentifier(_ identifier: String) -> Bool {
        if identifier.hasPrefix("payment-") { return true }
        return isLegacyUnprefixedPaymentIdentifier(identifier)
    }

    /// Legacy payments used `{uuid}-Ndays` without a type prefix.
    private static func isLegacyUnprefixedPaymentIdentifier(_ identifier: String) -> Bool {
        guard !identifier.hasPrefix("reminder-"),
              !identifier.hasPrefix("payment-") else { return false }
        guard identifier.count >= 38 else { return false }
        let uuidPart = String(identifier.prefix(36))
        guard UUID(uuidString: uuidPart) != nil else { return false }
        return identifier.dropFirst(36).first == "-"
    }
}
