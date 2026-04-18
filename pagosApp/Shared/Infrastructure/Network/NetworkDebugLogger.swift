import Foundation

/// Request/response tracing hooks (no-op) to keep the Xcode console quiet.
enum NetworkDebugLogger {
    static func logRequest(_ operation: String, resource: String, details: [String: String] = [:]) {}

    static func logResponse(_ operation: String, resource: String, details: [String: String] = [:]) {}

    static func logFailure(_ operation: String, resource: String, error: Error, details: [String: String] = [:]) {}

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
}
