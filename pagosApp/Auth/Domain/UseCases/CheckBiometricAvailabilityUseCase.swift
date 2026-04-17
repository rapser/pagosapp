//
//  CheckBiometricAvailabilityUseCase.swift
//  pagosApp
//
//  Use Case to check if biometric authentication is available.
//  Clean Architecture - Domain Layer
//

import Foundation
import LocalAuthentication

/// Use case to check biometric availability and settings
protocol CheckBiometricAvailabilityUseCaseProtocol {
    func execute() async -> Bool
}

/// Implementation of biometric availability check
final class CheckBiometricAvailabilityUseCase: CheckBiometricAvailabilityUseCaseProtocol {
    
    func execute() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}
