//
//  OSLogDomainLogWriter.swift
//  pagosApp
//
//  Default `DomainLogWriter` backed by `Logger` (OSLog).
//

import Foundation
import OSLog

struct OSLogDomainLogWriter: DomainLogWriter {
    private let subsystem: String

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "pagosApp") {
        self.subsystem = subsystem
    }

    private func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    func debug(_ message: String, category: String) {
        logger(category: category).debug("\(message)")
    }

    func info(_ message: String, category: String) {
        logger(category: category).info("\(message)")
    }

    func warning(_ message: String, category: String) {
        logger(category: category).warning("\(message)")
    }

    func error(_ message: String, category: String) {
        logger(category: category).error("\(message)")
    }
}
