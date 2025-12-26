//
//  SessionManager.swift
//  pagosApp
//
//  Handles session state, timeouts, and inactivity tracking
//  Separated from AuthenticationManager for better Single Responsibility
//  Created by miguel tomairo on 26/12/25.
//

import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class SessionManager {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Session")

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionActiveKey = "sessionActive"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 week

    var isSessionActive = false
    var showInactivityAlert = false

    init() {
        self.isSessionActive = UserDefaults.standard.bool(forKey: sessionActiveKey)
    }

    // MARK: - Session Management

    func startSession() {
        isSessionActive = true
        UserDefaults.standard.set(true, forKey: sessionActiveKey)
        updateLastActiveTimestamp()
        logger.info("✅ Session started")
    }

    func endSession(dueToInactivity: Bool = false) {
        isSessionActive = false
        UserDefaults.standard.set(false, forKey: sessionActiveKey)
        UserDefaults.standard.removeObject(forKey: lastActiveTimestampKey)

        if dueToInactivity {
            showInactivityAlert = true
        }

    }

    func clearSession() {
        endSession()
        logger.info("🗑️ Session cleared")
    }

    // MARK: - Inactivity Tracking

    func checkSession() {
        #if DEBUG
        return // Don't check session timeout in debug mode
        #else
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            if elapsedTime > sessionTimeoutInSeconds {
                logger.warning("⏰ Session expired due to inactivity")
                endSession(dueToInactivity: true)
            }
        } else {
            updateLastActiveTimestamp()
        }
        #endif
    }

    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }

    // MARK: - Session Info

    var sessionDuration: TimeInterval? {
        guard let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(lastActiveTimestamp)
    }

    var sessionTimeRemaining: TimeInterval? {
        guard let duration = sessionDuration else { return nil }
        return max(0, sessionTimeoutInSeconds - duration)
    }
}
