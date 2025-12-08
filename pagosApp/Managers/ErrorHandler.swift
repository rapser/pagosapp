//
//  ErrorHandler.swift
//  pagosApp
//
//  Created by Claude Code
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftUI
import OSLog
import Observation

/// Protocol for errors that can be displayed to users
protocol UserFacingError: LocalizedError {
    var title: String { get }
    var recoverySuggestion: String? { get }
    var severity: ErrorSeverity { get }
}

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical

    var icon: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}

/// Centralized error handler for the app
@Observable
@MainActor
final class ErrorHandler {
    static let shared = ErrorHandler()

    var currentError: ErrorAlert?
    var showError = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ErrorHandler")

    private init() {}

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

/// Structure representing an error alert to display to the user
struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: ErrorSeverity
    let recoverySuggestion: String?

    var icon: String {
        severity.icon
    }
}

// MARK: - View Modifier

struct ErrorHandlingModifier: ViewModifier {
    @Environment(ErrorHandler.self) private var errorHandler

    func body(content: Content) -> some View {
        @Bindable var handler = errorHandler
        
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $handler.showError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK", role: .cancel) {
                    errorHandler.showError = false
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(error.icon) \(error.message)")

                    if let suggestion = error.recoverySuggestion {
                        Text("\n💡 \(suggestion)")
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    /// Add global error handling to a view
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}
