//
//  AppConfiguration.swift
//  pagosApp
//
//  App-level configuration reader from Info.plist
//  Clean Architecture - App Configuration Layer
//

import Foundation

/// App configuration reader from Info.plist
enum AppConfiguration {

    /// Get a configuration value from Info.plist
    /// - Parameter key: The configuration key
    /// - Returns: The configuration value
    /// - Throws: ConfigurationError if the key is missing or invalid
    private static func value<T>(for key: String) throws -> T {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw ConfigurationError.missingKey(key)
        }

        guard let value = object as? T else {
            throw ConfigurationError.invalidValue(key)
        }

        return value
    }

    // MARK: - Supabase Configuration

    static var supabaseURL: URL {
        get throws {
            let urlString: String = try value(for: "SUPABASE_URL")
            let cleanedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let url = URL(string: cleanedURLString) else {
                throw ConfigurationError.invalidValue("SUPABASE_URL")
            }
            // `URL(string:)` acepta cualquier cadena sin esquema como URL "relativa" (host nil).
            // Los placeholders del template de CI pasaban esta comprobación y el SDK de Supabase podía crashear.
            guard isConfiguredSupabaseURL(url) else {
                throw ConfigurationError.invalidValue("SUPABASE_URL")
            }
            return url
        }
    }

    static var supabaseKey: String {
        get throws {
            let key: String = try value(for: "SUPABASE_KEY")
            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isConfiguredSupabaseKey(trimmed) else {
                throw ConfigurationError.invalidValue("SUPABASE_KEY")
            }
            return trimmed
        }
    }

    private static func isConfiguredSupabaseURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty else {
            return false
        }
        let lower = url.absoluteString.lowercased()
        if lower.contains("your_supabase") {
            return false
        }
        return true
    }

    private static func isConfiguredSupabaseKey(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        let lower = key.lowercased()
        if lower == "your_supabase_anon_key_here" || lower.contains("your_supabase") {
            return false
        }
        return true
    }
}
