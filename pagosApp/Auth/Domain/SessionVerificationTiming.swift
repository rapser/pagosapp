//
//  SessionVerificationTiming.swift
//  pagosApp
//
//  Centralizes delays used around remote session verification (presentation stability).
//

import Foundation

enum SessionVerificationTiming {
    /// Delay before querying remote auth when `allowNetworkDelay` is true (cold start / UI wiring).
    static let networkStabilityDelay: Duration = .seconds(1) + .milliseconds(500)
}
