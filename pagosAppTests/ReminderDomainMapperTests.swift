//
//  ReminderDomainMapperTests.swift
//  pagosAppTests
//

import Foundation
import Testing
@testable import pagosApp

struct ReminderDomainMapperTests {

    @Test func roundTripDTOPreservesCoreFields() {
        let id = UUID()
        let due = Date(timeIntervalSince1970: 1_800_000_000)
        let last = Date(timeIntervalSince1970: 1_800_000_3600)

        let settings = NotificationSettings(
            oneMonthBefore: true,
            twoWeeksBefore: false,
            oneWeekBefore: false
        )

        let dto = ReminderLocalDTO(
            id: id,
            reminderType: .subscription,
            title: "Sub",
            reminderDescription: "Desc",
            dueDate: due,
            isCompleted: false,
            notificationSettings: settings,
            syncStatus: .modified,
            lastSyncedAt: last
        )

        let domain = ReminderDomainMapper.toDomain(dto)
        #expect(domain.id == id)
        #expect(domain.reminderType == .subscription)
        #expect(domain.title == "Sub")
        #expect(domain.description == "Desc")
        #expect(domain.dueDate == due)
        #expect(domain.isCompleted == false)
        #expect(domain.syncStatus == .modified)
        #expect(domain.lastSyncedAt == last)

        let back = ReminderDomainMapper.toDTO(domain)
        #expect(back.id == id)
        #expect(back.title == "Sub")
        #expect(back.reminderDescription == "Desc")
        #expect(back.dueDate == due)
    }
}
