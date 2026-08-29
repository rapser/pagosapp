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

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Reminders.Notifications.header)
                            .font(.headline)
                        Text("Siempre incluye: 3, 2, 1 día antes y el mismo día")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(spacing: 20) {
                    Toggle(L10n.Reminders.Notifications.twoWeeksBefore, isOn: $notificationSettings.twoWeeksBefore)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))

                    Toggle(L10n.Reminders.Notifications.oneWeekBefore, isOn: $notificationSettings.oneWeekBefore)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .padding(.leading, 8)
            }
        } footer: {
            Text(footerText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var footerText: String {
        notificationSettings.hasAdvancedNotifications
            ? "💡 Notificaciones adicionales activadas para mayor anticipación"
            : "Puedes activar notificaciones adicionales con más anticipación"
    }
}

#Preview {
    @Previewable @State var settings = NotificationSettings.recommended(for: .cardRenewal)

    NavigationView {
        Form {
            NotificationSettingsView(notificationSettings: $settings)
        }
        .navigationTitle("Notification Settings")
    }
}
