//
//  Reminder.swift
//  pagosApp
//
//  Domain entity for Reminder (Sendable, thread-safe).
//  Clean Architecture: Domain layer - no amount; type, title, dueDate only.
//

import Foundation

/// Sendable domain entity for a reminder (no payment amount).
/// Includes sync fields for offline-first sync with Supabase.
struct Reminder: Sendable {
    let id: UUID
    let reminderType: ReminderType
    let title: String
    let dueDate: Date
    let syncStatus: ReminderSyncStatus
    let lastSyncedAt: Date?
}
