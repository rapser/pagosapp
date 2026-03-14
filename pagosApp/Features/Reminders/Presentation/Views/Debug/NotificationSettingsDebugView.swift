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
                Section("Pension Reminder") {
                    NotificationSettingsView(
                        notificationSettings: $pensionSettings,
                        reminderType: .pension
                    )
                }
                
                Section("Savings Reminder") {
                    NotificationSettingsView(
                        notificationSettings: $savingsSettings,
                        reminderType: .savings
                    )
                }
                
                Section("Other Reminder") {
                    NotificationSettingsView(
                        notificationSettings: $otherSettings,
                        reminderType: .other
                    )
                }
                
                Section("Debug Info") {
                    Group {
                        Text("Pension days: \(pensionSettings.allNotificationDays.map(String.init).joined(separator: ", "))")
                        Text("Savings days: \(savingsSettings.allNotificationDays.map(String.init).joined(separator: ", "))")
                        Text("Other days: \(otherSettings.allNotificationDays.map(String.init).joined(separator: ", "))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notification Settings Debug")
        }
    }
}

#Preview {
    NotificationSettingsDebugView()
}