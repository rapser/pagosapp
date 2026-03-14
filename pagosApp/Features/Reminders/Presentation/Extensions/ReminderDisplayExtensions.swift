//
//  ReminderDisplayExtensions.swift
//  pagosApp
//
//  Extensions for Reminder display logic (similar to PaymentUI)
//  Clean Architecture - Presentation Layer
//

import SwiftUI
import Foundation

extension Reminder {
    /// Icon for reminder status
    var statusIcon: String {
        isCompleted ? "checkmark.circle.fill" : "circle"
    }
    
    /// Color for the status icon
    var statusColor: Color {
        isCompleted ? Color("AppSuccess") : Color("AppTextSecondary")
    }
    
    /// Opacity for display (completed items are less prominent)
    var displayOpacity: Double {
        isCompleted ? 0.7 : 1.0
    }
    
    /// Whether the reminder is overdue
    /// A reminder is considered overdue only after midnight of the due date
    /// (i.e., if due date is Jan 15, it becomes overdue on Jan 16 at 00:00:00)
    var isOverdue: Bool {
        guard !isCompleted else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDateStart = calendar.startOfDay(for: dueDate)
        // Overdue only if due date is before today (not same day)
        return dueDateStart < today
    }
    
    /// Display color based on reminder state
    var displayColor: Color {
        if isCompleted {
            return Color("AppSuccess")
        } else if isOverdue {
            return Color.red
        } else {
            return Color("AppTextPrimary")
        }
    }
    
    /// Formatted date string
    var formattedDate: String {
        DateFormattingService.formatMedium(dueDate)
    }
}