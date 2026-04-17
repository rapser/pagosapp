//
//  VerifyRemoteSessionUseCase.swift
//  pagosApp
//
//  Use Case to verify session validity against remote server.
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case to verify session status remotely with proper error handling
protocol VerifyRemoteSessionUseCaseProtocol {
    func execute(allowNetworkDelay: Bool) async -> SessionVerificationResult
}

/// Result of remote session verification
enum SessionVerificationResult {
    case valid
    case invalid
    case networkError(Error)
    case timeout
}

/// Implementation of remote session verification
final class VerifyRemoteSessionUseCase: VerifyRemoteSessionUseCaseProtocol {
    
    private let getAuthenticationStatusUseCase: GetAuthenticationStatusUseCase
    
    init(getAuthenticationStatusUseCase: GetAuthenticationStatusUseCase) {
        self.getAuthenticationStatusUseCase = getAuthenticationStatusUseCase
    }
    
    func execute(allowNetworkDelay: Bool = true) async -> SessionVerificationResult {
        do {
            // Add delay for network stability if requested 
            if allowNetworkDelay {
                try await Task.sleep(for: SessionVerificationTiming.networkStabilityDelay)
            }
            
            let hasActiveSession = await getAuthenticationStatusUseCase.execute()
            return hasActiveSession ? .valid : .invalid
            
        } catch {
            // Differentiate between timeout and other network errors
            if error is CancellationError {
                return .timeout
            } else {
                return .networkError(error)
            }
        }
    }
}
