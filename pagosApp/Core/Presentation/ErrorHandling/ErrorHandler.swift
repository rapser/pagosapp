//
//  ErrorHandler.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftUI
import OSLog
import Observation

/// Centralized error handler for the app
/// Refactored to support Dependency Injection (no more Singleton)
@Observable
@MainActor
final class ErrorHandler {
    var currentError: ErrorAlert?
    var showError = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ErrorHandler")

    // MARK: - Initialization

    init() {}

    /// Handle an error with user feedback
    func handle(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("[\(fileName):\(line)] \(function) - Error: \(error.localizedDescription)")

        if let userError = error as? UserFacingError {
            showUserError(userError)
        } else {
            // Generic error handling
            showGenericError(error)
        }
    }

    /// Show a user-facing error
    private func showUserError(_ error: UserFacingError) {
        logger.log(level: logLevel(for: error.severity), "\(error.severity.icon) \(error.title): \(error.localizedDescription)")

        currentError = ErrorAlert(
            title: error.title,
            message: error.localizedDescription,
            severity: error.severity,
            recoverySuggestion: error.recoverySuggestion
        )
        showError = true
    }

    /// Show a generic error with fallback messaging
    private func showGenericError(_ error: Error) {
        logger.error("❌ Unexpected error: \(error.localizedDescription)")

        currentError = ErrorAlert(
            title: "Error inesperado",
            message: error.localizedDescription,
            severity: .error,
            recoverySuggestion: "Por favor, intenta nuevamente. Si el problema persiste, contacta soporte."
        )
        showError = true
    }

    /// Convert severity to OSLog level
    private func logLevel(for severity: ErrorSeverity) -> OSLogType {
        switch severity {
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }

    /// Log info without showing alert
    func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Log warning without showing alert
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("[\(fileName):\(line)] \(function) - \(message)")
    }
}

extension View {
    /// Add global error handling to a view
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}
