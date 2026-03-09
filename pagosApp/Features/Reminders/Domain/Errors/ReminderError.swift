//
//  ReminderError.swift
//  pagosApp
//
//  Domain errors for Reminders feature.
//

import Foundation

enum ReminderError: Error {
    case invalidTitle
    case invalidDate
    case saveFailed(String)
    case deleteFailed(String)
    case notFound
    case unknown(String)
}
