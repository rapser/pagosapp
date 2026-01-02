//
//  ErrorHandler.swift
//  pagosApp
//
//  Error handling utility for presentation layer
//  Clean Architecture: Presentation utility
//

import Foundation
import OSLog
import Observation

/// Simple error handler for presentation layer
/// Logs errors and can present them to the user
@MainActor
@Observable
final class ErrorHandler {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ErrorHandler")

    var currentError: Error?
    var showError: Bool = false

    init() {}

    /// Handle an error by logging it
    func handle(_ error: Error) {
        logger.error("❌ Error: \(error.localizedDescription)")
        currentError = error
        showError = true
    }

    /// Handle an error with custom message
    func handle(_ error: Error, message: String) {
        logger.error("❌ \(message): \(error.localizedDescription)")
        currentError = error
        showError = true
    }

    /// Clear current error
    func clearError() {
        currentError = nil
        showError = false
    }
}
