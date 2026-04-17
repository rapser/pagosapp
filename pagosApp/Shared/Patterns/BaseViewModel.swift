//
//  BaseViewModel.swift
//  pagosApp
//
//  Base ViewModel class providing common functionality across all ViewModels
//  Clean Architecture - Shared Pattern
//

import Foundation
import SwiftUI
import OSLog

/// Base ViewModel class providing common functionality to eliminate code duplication
@MainActor
@Observable
class BaseViewModel: LoadingStateViewModel {
    // MARK: - LoadingStateViewModel Conformance
    var isLoading = false
    var errorMessage: String?
    var showError = false
    
    // MARK: - Common Properties
    let logger: Logger
    
    // MARK: - Initialization
    
    init(category: String) {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", 
            category: category
        )
    }
    
    convenience init() {
        let className = String(describing: type(of: self))
        self.init(category: className)
    }
    
    // MARK: - Common Methods
    
    /// Log debug messages with automatic class context
    func logDebug(_ message: String, function: String = #function, line: Int = #line) {
        logger.debug("\(function):\(line) - \(message)")
    }
    
    /// Log error messages with automatic class context
    func logError(_ error: Error, function: String = #function, line: Int = #line) {
        logger.error("\(function):\(line) - \(error.localizedDescription)")
    }
    
    /// Handle common async operations with loading state and error handling
    @discardableResult
    func withLoadingAndErrorHandling<T>(
        operation: @escaping () async throws -> T,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) async -> T? {
        return await withLoading {
            do {
                let result = try await operation()
                onSuccess?(result)
                return result
            } catch {
                logError(error)
                onError?(error)
                throw error
            }
        }
    }
    
    /// Reset ViewModel to initial state
    func reset() {
        isLoading = false
        clearError()
    }
}

// MARK: - Extensions

extension BaseViewModel {
    /// Convenience method for handling validation errors
    func setValidationError(_ message: String) {
        logDebug("Validation error: \(message)")
        setError(message)
    }
    
    /// Convenience method for handling network errors
    func handleNetworkError(_ error: Error) {
        logError(error)
        if let networkError = error as? URLError {
            switch networkError.code {
            case .notConnectedToInternet:
                setError(L10n.General.networkOffline)
            case .timedOut:
                setError(L10n.General.networkTimeout)
            default:
                setError(L10n.General.networkGeneric)
            }
        } else {
            setError(error.localizedDescription)
        }
    }
}