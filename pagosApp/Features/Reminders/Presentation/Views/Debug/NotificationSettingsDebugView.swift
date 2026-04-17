//
//  NotificationSettingsDebugView.swift
//  pagosApp
//
//  Debug view for testing notification settings functionality.
//  Clean Architecture - Presentation (Debug/Testing).
//

import SwiftUI

struct NotificationSettingsDebugView: View {
    @State private var pensionSettings = NotificationSettings.recommended(for: .pension)
    @State private var savingsSettings = NotificationSettings.recommended(for: .savings)
    @State private var otherSettings = NotificationSettings.recommended(for: .other)

    var body: some View {
        NavigationView {
            Form {
                Section(L10n.Debug.NotificationSettings.sectionPension) {
                    NotificationSettingsView(
                        notificationSettings: $pensionSettings,
                        reminderType: .pension
                    )
                }

                Section(L10n.Debug.NotificationSettings.sectionSavings) {
                    NotificationSettingsView(
                        notificationSettings: $savingsSettings,
                        reminderType: .savings
                    )
                }

                Section(L10n.Debug.NotificationSettings.sectionOther) {
                    NotificationSettingsView(
                        notificationSettings: $otherSettings,
                        reminderType: .other
                    )
                }

                Section(L10n.Debug.NotificationSettings.sectionDebugInfo) {
                    Group {
                        Text(L10n.Debug.NotificationSettings.pensionDays(pensionSettings.allNotificationDays.map(String.init).joined(separator: ", ")))
                        Text(L10n.Debug.NotificationSettings.savingsDays(savingsSettings.allNotificationDays.map(String.init).joined(separator: ", ")))
                        Text(L10n.Debug.NotificationSettings.otherDays(otherSettings.allNotificationDays.map(String.init).joined(separator: ", ")))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle(L10n.Debug.NotificationSettings.navTitle)
        }
    }
}

#Preview {
    NotificationSettingsDebugView()
}
