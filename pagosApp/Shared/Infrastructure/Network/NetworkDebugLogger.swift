import Foundation
import OSLog

enum NetworkDebugLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "pagosApp",
        category: "NetworkDebug"
    )

    static func logRequest(_ operation: String, resource: String, details: [String: String] = [:]) {
#if DEBUG
        logger.debug("➡️ \(sanitize(operation)) [\(sanitize(resource))] \(sanitize(format(details)))")
#endif
    }

    static func logResponse(_ operation: String, resource: String, details: [String: String] = [:]) {
#if DEBUG
        logger.debug("✅ \(sanitize(operation)) [\(sanitize(resource))] \(sanitize(format(details)))")
#endif
    }

    static func logFailure(_ operation: String, resource: String, error: Error, details: [String: String] = [:]) {
#if DEBUG
        logger.error("❌ \(sanitize(operation)) [\(sanitize(resource))] \(sanitize(format(details))) error=\(sanitize(error.localizedDescription))")
#endif
    }

    static func redactEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1)
        guard parts.count == 2 else { return "<redacted-email>" }
        let local = String(parts[0])
        let domain = String(parts[1])
        let prefix = local.prefix(2)
        return "\(prefix)***@\(domain)"
    }

    static func redactIdentifier(_ identifier: String) -> String {
        guard identifier.count > 8 else { return "***" }
        return "\(identifier.prefix(4))...\(identifier.suffix(4))"
    }

    private static func format(_ details: [String: String]) -> String {
        guard !details.isEmpty else { return "" }
        return details
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
    }

    private static func sanitize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
