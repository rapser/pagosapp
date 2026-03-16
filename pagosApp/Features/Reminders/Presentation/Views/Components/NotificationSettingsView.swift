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
                // Header
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Reminders.Notifications.header)
                            .font(.headline)
                        Text(standardNotificationsText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                // Advanced options based on type
                if reminderType.requiresAdvancedNotifications {
                    VStack(spacing: 20) {
                        Toggle(L10n.Reminders.Notifications.oneMonthBefore, isOn: $notificationSettings.oneMonthBefore)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                        
                        Toggle(L10n.Reminders.Notifications.twoWeeksBefore, isOn: $notificationSettings.twoWeeksBefore)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                    }
                    .padding(.leading, 8)
                } else {
                    Toggle(L10n.Reminders.Notifications.oneWeekBefore, isOn: $notificationSettings.oneWeekBefore)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.leading, 8)
                }
            }
        } footer: {
            Text(footerText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var standardNotificationsText: String {
        "Siempre incluye: 3, 2, 1 día antes y el mismo día"
    }
    
    private var footerText: String {
        if reminderType.requiresAdvancedNotifications {
            if notificationSettings.oneMonthBefore || notificationSettings.twoWeeksBefore {
                return "💡 Notificaciones adicionales activadas para mayor anticipación"
            } else {
                return "Para este tipo de recordatorio puedes activar notificaciones con más anticipación"
            }
        } else {
            if notificationSettings.oneWeekBefore {
                return "💡 Notificación de 1 semana antes activada"
            } else {
                return "Puedes activar una notificación adicional con 1 semana de anticipación"
            }
        }
    }
}

#Preview {
    @Previewable @State var importantSettings = NotificationSettings.recommended(for: .cardRenewal)
    @Previewable @State var simpleSettings = NotificationSettings.recommended(for: .savings)
    
    NavigationView {
        Form {
            NotificationSettingsView(notificationSettings: $importantSettings, reminderType: .cardRenewal)
            
            NotificationSettingsView(notificationSettings: $simpleSettings, reminderType: .savings)
        }
        .navigationTitle("Notification Settings")
    }
}
