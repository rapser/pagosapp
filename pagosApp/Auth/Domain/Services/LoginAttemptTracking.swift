//
//  LoginAttemptTracking.swift
//  pagosApp
//
//  Tracks failed password login attempts per email (normalized) for lockout (M4).
//

import Foundation

/// Tracks email/password login failures and temporary lockout per normalized email.
@MainActor
protocol LoginAttemptTracking: AnyObject {
    /// If non-nil and in the future, login must be rejected until that instant.
    func lockoutUntilIfActive(forNormalizedEmail email: String) -> Date?
    func recordFailedPasswordAttempt(forNormalizedEmail email: String)
    func recordSuccessfulLogin(forNormalizedEmail email: String)
}
