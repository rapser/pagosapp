//
//  DateFormattingService.swift
//  pagosApp
//
//  Shared utility for consistent date formatting across the app
//  Clean Architecture: Core/Utils layer
//

import Foundation

/// Service for formatting dates consistently across the app
struct DateFormattingService {

    /// Get the app's locale (currently es_PE, but can be made configurable)
    static var appLocale: Locale {
        Locale(identifier: "es_PE")
    }

    /// Format a date with medium style using app's locale
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string (e.g., "15 ene 2026")
    static func formatMedium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Format a date with short style using app's locale
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string (e.g., "15/01/26")
    static func formatShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    /// Format a date with long style using app's locale
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string (e.g., "15 de enero de 2026")
    static func formatLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
