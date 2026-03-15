//
//  ReminderRowView.swift
//  pagosApp
//
//  Celda de recordatorio: mismo estilo que PaymentRowView.
//  Círculo para marcar completado/cancelado; título, tipo y fecha; descripción solo al abrir.
//

import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    var onToggleStatus: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggleStatus) {
                Image(systemName: reminder.statusIcon)
                    .foregroundColor(reminder.statusColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .fontWeight(.bold)
                    .font(.body)
                    .strikethrough(reminder.isCompleted, color: Color("AppTextSecondary"))
                    .foregroundColor(reminder.displayColor)
                Text(L10n.Reminders.typeDisplayName(reminder.reminderType))
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            Text(reminder.formattedDate)
                .font(.caption)
                .strikethrough(reminder.isCompleted, color: Color("AppTextSecondary"))
                .foregroundColor(reminder.displayColor)
        }
        .opacity(reminder.displayOpacity)
    }
}
