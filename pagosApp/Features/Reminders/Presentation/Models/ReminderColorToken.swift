//
//  ReminderColorToken.swift
//  pagosApp
//
//  Presentation-agnostic display tokens for reminder rows (no SwiftUI).
//

import Foundation

enum ReminderColorToken: Equatable, Sendable {
    case appSuccess
    case appTextSecondary
    case appTextPrimary
    case overdue
}

extension Reminder {
    var statusIcon: String {
        isCompleted ? "checkmark.circle.fill" : "circle"
    }

    var statusColorToken: ReminderColorToken {
        isCompleted ? .appSuccess : .appTextSecondary
    }

    var displayOpacity: Double {
        isCompleted ? 0.7 : 1.0
    }

    /// Overdue only after midnight of the due date (same rule as payments).
    var isOverdue: Bool {
        guard !isCompleted else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDateStart = calendar.startOfDay(for: dueDate)
        return dueDateStart < today
    }

    var displayColorToken: ReminderColorToken {
        if isCompleted {
            return .appSuccess
        } else if isOverdue {
            return .overdue
        } else {
            return .appTextPrimary
        }
    }

    var formattedDate: String {
        DateFormattingService.formatMedium(dueDate)
    }
}
