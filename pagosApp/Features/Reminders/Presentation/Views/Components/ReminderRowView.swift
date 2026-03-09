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

    private var statusIcon: String {
        reminder.isCompleted ? "checkmark.circle.fill" : "circle"
    }

    private var statusColor: Color {
        reminder.isCompleted ? Color("AppSuccess") : Color("AppTextSecondary")
    }

    private var displayColor: Color {
        reminder.isCompleted ? Color("AppSuccess") : Color("AppTextPrimary")
    }

    private var displayOpacity: Double {
        reminder.isCompleted ? 0.7 : 1.0
    }

    var body: some View {
        HStack {
            Button(action: onToggleStatus) {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .fontWeight(.bold)
                    .font(.body)
                    .strikethrough(reminder.isCompleted, color: Color("AppTextSecondary"))
                    .foregroundColor(displayColor)
                Text(L10n.Reminders.typeDisplayName(reminder.reminderType))
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            Text(DateFormattingService.formatMedium(reminder.dueDate))
                .font(.caption)
                .strikethrough(reminder.isCompleted, color: Color("AppTextSecondary"))
                .foregroundColor(displayColor)
        }
        .opacity(displayOpacity)
    }
}
