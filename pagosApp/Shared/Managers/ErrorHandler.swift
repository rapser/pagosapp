//
//  ErrorHandler.swift
//  pagosApp
//
//  Error handling utility for presentation layer
//  Clean Architecture: Presentation utility
//

import Foundation
import Observation

/// Simple error handler for presentation layer
/// Logs errors and can present them to the user
@MainActor
@Observable
final class ErrorHandler {
    private static let logCategory = "ErrorHandler"

    private let log: DomainLogWriter

    var currentError: Error?
    var showError: Bool = false

    init(log: DomainLogWriter) {
        self.log = log
    }

    /// Handle an error by logging it
    func handle(_ error: Error) {
        log.error("❌ Error: \(error.localizedDescription)", category: Self.logCategory)
        currentError = error
        showError = true
    }

    /// Handle an error with custom message
    func handle(_ error: Error, message: String) {
        log.error("❌ \(message): \(error.localizedDescription)", category: Self.logCategory)
        currentError = error
        showError = true
    }

    /// Clear current error
    func clearError() {
        currentError = nil
        showError = false
    }
}
