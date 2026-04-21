//
//  DomainLogWriter.swift
//  pagosApp
//
//  Logging port for Domain / use cases (no OSLog import in business rules).
//

import Foundation

/// Abstraction for structured logging from use cases without tying Domain to `OSLog`.
protocol DomainLogWriter: Sendable {
    func debug(_ message: String, category: String)
    func info(_ message: String, category: String)
    func warning(_ message: String, category: String)
    func error(_ message: String, category: String)
}
