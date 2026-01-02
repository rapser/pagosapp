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
            return url
        }
    }

    static var supabaseKey: String {
        get throws {
            try value(for: "SUPABASE_KEY")
        }
    }
}
