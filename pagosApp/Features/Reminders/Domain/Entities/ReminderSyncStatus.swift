//
//  ReminderSyncStatus.swift
//  pagosApp
//
//  Sync status for reminder synchronization with Supabase.
//  Clean Architecture - Domain Layer (own type for reminders, independent of payments).
//

import Foundation

/// Sync status for tracking reminder synchronization state
enum ReminderSyncStatus: String, Sendable {
    case local    // Only exists locally, never synced
    case syncing  // Sync in progress
    case synced   // Successfully synced with Supabase
    case modified // Exists in Supabase but was modified locally
    case error    // Sync failed
}
