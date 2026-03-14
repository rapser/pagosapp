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
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and title
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Reminders.Notifications.header)
                            .font(.headline)
                        
                        Text(L10n.Reminders.Notifications.basicIncluded)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // Advanced notifications section
                if hasAdvancedOptions {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.badge.plus")
                                .foregroundStyle(.orange)
                                .font(.callout)
                            
                            Text(L10n.Reminders.Notifications.advancedTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.top, 4)
                        
                        VStack(spacing: 20) {
                            Toggle(L10n.Reminders.Notifications.oneMonthBefore, isOn: $notificationSettings.oneMonthBefore)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                            
                            Toggle(L10n.Reminders.Notifications.twoWeeksBefore, isOn: $notificationSettings.twoWeeksBefore)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                            
                            Toggle(L10n.Reminders.Notifications.oneWeekBefore, isOn: $notificationSettings.oneWeekBefore) 
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                        .padding(.leading, 16)
                    }
                } else {
                    // Simple message when no advanced options
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        Text(L10n.Reminders.Notifications.optimalConfig)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        } footer: {
            if notificationSettings.hasAdvancedNotifications {
                Label(L10n.Reminders.Notifications.advancedInfo, systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var hasAdvancedOptions: Bool {
        // Show advanced options for important reminder types
        switch reminderType {
        case .cardRenewal, .documents, .taxes, .membership, .subscription, .pension:
            return true
        case .savings, .deposit, .other:
            return false
        }
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
