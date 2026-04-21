//
//  SessionRepositoryImpl.swift
//  pagosApp
//
//  Implementation of Session repository (Clean Architecture)
//  Clean Architecture - Data Layer
//

import Foundation

/// Implementation of SessionRepositoryProtocol
/// Manages session state and timeout using UserDefaults
@MainActor
final class SessionRepositoryImpl: SessionRepositoryProtocol {
    private static let logCategory = "SessionRepositoryImpl"

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionActiveKey = "sessionActive"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 week

    private let userDefaults: UserDefaults
    private let log: DomainLogWriter

    init(userDefaults: UserDefaults = .standard, log: DomainLogWriter) {
        self.userDefaults = userDefaults
        self.log = log
    }

    // MARK: - Session State

    var hasActiveSession: Bool {
        userDefaults.bool(forKey: sessionActiveKey)
    }

    var lastActiveTimestamp: Date? {
        userDefaults.object(forKey: lastActiveTimestampKey) as? Date
    }

    /// Check if session is expired synchronously (for UI initialization)
    var isSessionExpiredSync: Bool {
        #if DEBUG
        // Don't check session timeout in debug mode
        return false
        #else
        guard let lastActive = lastActiveTimestamp else {
            log.debug("⚠️ No last active timestamp found", category: Self.logCategory)
            return true
        }

        let elapsedTime = Date().timeIntervalSince(lastActive)
        let isExpired = elapsedTime > self.sessionTimeoutInSeconds

        if isExpired {
            log.debug(
                "⏰ Session expired (sync check) - elapsed: \(elapsedTime)s, timeout: \(self.sessionTimeoutInSeconds)s",
                category: Self.logCategory
            )
        }

        return isExpired
        #endif
    }

    // MARK: - Session Operations

    func startSession() async {
        log.info("✅ Starting session", category: Self.logCategory)
        userDefaults.set(true, forKey: sessionActiveKey)
        await updateLastActiveTimestamp()
    }

    func endSession() async {
        log.info("🛑 Ending session", category: Self.logCategory)
        userDefaults.set(false, forKey: sessionActiveKey)
        userDefaults.removeObject(forKey: lastActiveTimestampKey)
    }

    func clearSession() async {
        log.info("🗑️ Clearing session", category: Self.logCategory)
        await endSession()
    }

    func updateLastActiveTimestamp() async {
        userDefaults.set(Date(), forKey: lastActiveTimestampKey)
        log.debug("⏱️ Updated last active timestamp", category: Self.logCategory)
    }

    func isSessionExpired() async -> Bool {
        #if DEBUG
        // Don't check session timeout in debug mode
        return false
        #else
        guard let lastActive = lastActiveTimestamp else {
            log.debug("⚠️ No last active timestamp found", category: Self.logCategory)
            return true
        }

        let elapsedTime = Date().timeIntervalSince(lastActive)
        let isExpired = elapsedTime > self.sessionTimeoutInSeconds

        if isExpired {
            log.warning(
                "⏰ Session expired - elapsed: \(elapsedTime)s, timeout: \(self.sessionTimeoutInSeconds)s",
                category: Self.logCategory
            )
        }

        return isExpired
        #endif
    }

    func sessionTimeRemaining() async -> TimeInterval {
        guard let lastActive = lastActiveTimestamp else {
            return 0
        }

        let elapsedTime = Date().timeIntervalSince(lastActive)
        let remaining = max(0, sessionTimeoutInSeconds - elapsedTime)

        log.debug("⏳ Session time remaining: \(remaining)s", category: Self.logCategory)

        return remaining
    }

    func validateSession() async -> Result<Bool, AuthError> {
        // Check if session is active
        guard hasActiveSession else {
            log.debug("❌ No active session", category: Self.logCategory)
            return .success(false)
        }

        // Check if session is expired
        let expired = await isSessionExpired()

        if expired {
            log.warning("❌ Session is expired", category: Self.logCategory)
            return .failure(.sessionExpired)
        }

        log.debug("✅ Session is valid", category: Self.logCategory)
        return .success(true)
    }
}
