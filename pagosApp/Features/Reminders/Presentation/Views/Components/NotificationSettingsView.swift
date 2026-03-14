//
//  NotificationSettingsView.swift
//  pagosApp
//
//  Component for configuring notification settings for reminders.
//  Clean Architecture - Presentation (Reminders feature).
//

import SwiftUI

struct NotificationSettingsView: View {
    @Binding var notificationSettings: NotificationSettings
    let reminderType: ReminderType
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Reminders.Notifications.sectionTitle)
                    .font(.headline)
                
                Text(L10n.Reminders.Notifications.defaultDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Advanced notifications toggle section
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Reminders.Notifications.advancedTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(L10n.Reminders.Notifications.advancedDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 4) {
                        Toggle(L10n.Reminders.Notifications.oneMonthBefore, isOn: $notificationSettings.oneMonthBefore)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        
                        Toggle(L10n.Reminders.Notifications.twoWeeksBefore, isOn: $notificationSettings.twoWeeksBefore)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        
                        Toggle(L10n.Reminders.Notifications.oneWeekBefore, isOn: $notificationSettings.oneWeekBefore)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    .padding(.leading, 8)
                }
                .padding(.top, 8)
            }
        } header: {
            HStack {
                Image(systemName: "bell")
                    .foregroundStyle(.secondary)
                Text(L10n.Reminders.Notifications.header)
            }
        } footer: {
            Text(getFooterText())
                .font(.caption2)
        }
    }
    
    private func getFooterText() -> String {
        let days = notificationSettings.allNotificationDays
        
        if days.isEmpty {
            return L10n.Reminders.Notifications.noNotifications
        }
        
        let dayStrings = days.map { day in
            if day == 0 {
                return L10n.Reminders.Notifications.dayOf
            } else if day == 1 {
                return L10n.Reminders.Notifications.oneDayBefore
            } else {
                return L10n.Reminders.Notifications.daysBefore(day)
            }
        }
        
        return L10n.Reminders.Notifications.willNotifyOn + ": " + dayStrings.joined(separator: ", ")
    }
}

#Preview {
    @Previewable @State var settings = NotificationSettings.recommended(for: .pension)
    
    NavigationView {
        Form {
            NotificationSettingsView(notificationSettings: $settings, reminderType: .pension)
        }
        .navigationTitle("Notification Settings")
    }
}