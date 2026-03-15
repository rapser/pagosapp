//
//  SessionRepositoryImpl.swift
//  pagosApp
//
//  Implementation of Session repository (Clean Architecture)
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SessionRepositoryImpl")

/// Implementation of SessionRepositoryProtocol
/// Manages session state and timeout using UserDefaults
@MainActor
final class SessionRepositoryImpl: SessionRepositoryProtocol {
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionActiveKey = "sessionActive"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 week

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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
            logger.debug("⚠️ No last active timestamp found")
            return true
        }

        let elapsedTime = Date().timeIntervalSince(lastActive)
        let isExpired = elapsedTime > self.sessionTimeoutInSeconds

        if isExpired {
            logger.debug("⏰ Session expired (sync check) - elapsed: \(elapsedTime)s, timeout: \(self.sessionTimeoutInSeconds)s")
        }

        return isExpired
        #endif
    }

    // MARK: - Session Operations

    func startSession() async {
        logger.info("✅ Starting session")
        userDefaults.set(true, forKey: sessionActiveKey)
        await updateLastActiveTimestamp()
    }

    func endSession() async {
        logger.info("🛑 Ending session")
        userDefaults.set(false, forKey: sessionActiveKey)
        userDefaults.removeObject(forKey: lastActiveTimestampKey)
    }

    func clearSession() async {
        logger.info("🗑️ Clearing session")
        await endSession()
    }

    func updateLastActiveTimestamp() async {
        userDefaults.set(Date(), forKey: lastActiveTimestampKey)
        logger.debug("⏱️ Updated last active timestamp")
    }

    func isSessionExpired() async -> Bool {
        #if DEBUG
        // Don't check session timeout in debug mode
        return false
        #else
        guard let lastActive = lastActiveTimestamp else {
            logger.debug("⚠️ No last active timestamp found")
            return true
        }

        let elapsedTime = Date().timeIntervalSince(lastActive)
        let isExpired = elapsedTime > self.sessionTimeoutInSeconds

        if isExpired {
            logger.warning("⏰ Session expired - elapsed: \(elapsedTime)s, timeout: \(self.sessionTimeoutInSeconds)s")
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

        logger.debug("⏳ Session time remaining: \(remaining)s")

        return remaining
    }

    func validateSession() async -> Result<Bool, AuthError> {
        // Check if session is active
        guard hasActiveSession else {
            logger.debug("❌ No active session")
            return .success(false)
        }

        // Check if session is expired
        let expired = await isSessionExpired()

        if expired {
            logger.warning("❌ Session is expired")
            return .failure(.sessionExpired)
        }

        logger.debug("✅ Session is valid")
        return .success(true)
    }
}
