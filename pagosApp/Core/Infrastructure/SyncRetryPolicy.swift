//
//  SyncRetryPolicy.swift
//  pagosApp
//
//  Shared exponential-style backoff for sync coordinators (payments, reminders).
//

import Foundation

enum SyncRetryPolicy {
    static let maxAttempts = 3

    private static let baseDelaysNanoseconds: [UInt64] = [
        500_000_000,
        1_000_000_000,
        2_000_000_000
    ]

    private static let jitterUpperBoundNanoseconds: UInt64 = 250_000_000

    /// Delay for `attempt` (1-based), used before the next retry.
    static func delayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        let index = min(max(attempt - 1, 0), baseDelaysNanoseconds.count - 1)
        let base = baseDelaysNanoseconds[index]
        let jitter = UInt64.random(in: 0...jitterUpperBoundNanoseconds)
        return base + jitter
    }

    static func sleepBeforeRetry(forAttempt attempt: Int) async {
        try? await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
    }
}

/// Cooldown for sync entry points so burst events do not stack concurrent sync work.
@MainActor
final class SyncTriggerThrottle {
    private let minimumInterval: TimeInterval
    private var lastTriggerDate: Date?

    init(minimumInterval: TimeInterval) {
        self.minimumInterval = minimumInterval
    }

    /// Records this trigger and returns `true` if sync may proceed, `false` if still within cooldown.
    func consumeTriggerIfAllowed(now: Date = Date()) -> Bool {
        if let last = lastTriggerDate, now.timeIntervalSince(last) < minimumInterval {
            return false
        }
        lastTriggerDate = now
        return true
    }
}
