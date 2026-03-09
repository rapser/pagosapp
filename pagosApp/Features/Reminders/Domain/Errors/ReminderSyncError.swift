//
//  ReminderSyncError.swift
//  pagosApp
//
//  Domain errors for reminder sync with Supabase.
//  Clean Architecture - Domain Layer (own type, independent of payments).
//

import Foundation

/// Domain errors for reminder synchronization
enum ReminderSyncError: Error, Equatable {
    case notAuthenticated
    case uploadFailed(String)
    case downloadFailed(String)
    case unknown(String)

    var errorCode: String {
        switch self {
        case .notAuthenticated: return "REMINDER_SYNC_NOT_AUTHENTICATED"
        case .uploadFailed: return "REMINDER_SYNC_UPLOAD_FAILED"
        case .downloadFailed: return "REMINDER_SYNC_DOWNLOAD_FAILED"
        case .unknown: return "REMINDER_SYNC_UNKNOWN"
        }
    }
}
