//
//  LoadingState.swift
//  pagosApp
//
//  Base loading state pattern to eliminate boilerplate across ViewModels.
//  Clean Architecture - Shared Pattern
//

import Foundation
import SwiftUI

/// Protocol for ViewModels that have loading state
@MainActor
protocol LoadingStateViewModel: AnyObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var showError: Bool { get set }
}

/// Extension providing default implementation for loading state behavior
extension LoadingStateViewModel {
    func setError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
    
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }
    
    /// Execute an async operation with automatic loading state management
    @discardableResult
    func withLoading<T>(_ operation: () async throws -> T) async -> T? {
        isLoading = true
        clearError()
        
        defer {
            isLoading = false
        }
        
        do {
            return try await operation()
        } catch {
            setError(error.localizedDescription)
            return nil
        }
    }
}

/// Concrete implementation that ViewModels can inherit from or compose
@Observable
class BaseLoadingState: LoadingStateViewModel {
    var isLoading = false
    var errorMessage: String?
    var showError = false
}