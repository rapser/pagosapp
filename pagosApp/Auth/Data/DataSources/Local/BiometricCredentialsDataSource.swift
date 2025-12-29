//
//  BiometricCredentialsDataSource.swift
//  pagosApp
//
//  Protocol for biometric credentials storage
//  Clean Architecture - Data Layer
//

import Foundation
import LocalAuthentication

/// Protocol for storing and retrieving biometric login credentials
protocol BiometricCredentialsDataSource {
    /// Save email and password for biometric login
    func saveCredentials(email: String, password: String) -> Bool

    /// Retrieve email and password with biometric authentication
    func retrieveCredentials(context: LAContext?) -> (email: String, password: String)?

    /// Delete stored credentials
    func deleteCredentials() -> Bool

    /// Check if credentials are stored
    func hasStoredCredentials() -> Bool

    /// Save flag indicating user has logged in with credentials
    func setHasLoggedIn(_ value: Bool) -> Bool

    /// Check if user has logged in with credentials
    func getHasLoggedIn() -> Bool

    /// Delete has logged in flag
    func deleteHasLoggedIn() -> Bool
}
