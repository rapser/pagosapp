//
//  ConfigurationManagerTests.swift
//  pagosAppTests
//
//  Unit tests for ConfigurationManager
//

import XCTest
@testable import pagosApp

final class ConfigurationManagerTests: XCTestCase {

    func testSupabaseURLConfiguration() throws {
        // Given/When
        // Note: This test will fail if Info.plist doesn't have SUPABASE_URL
        // In real testing, you would mock Bundle or use a test-specific configuration

        // Then
        do {
            let url = try ConfigurationManager.supabaseURL
            XCTAssertNotNil(url, "Supabase URL should be configured")
            XCTAssertTrue(url.absoluteString.contains("supabase"), "URL should contain 'supabase'")
        } catch ConfigurationError.missingKey(let key) {
            // Expected in test environment without proper Info.plist
            XCTAssertEqual(key, "SUPABASE_URL")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSupabaseKeyConfiguration() throws {
        // Given/When
        // Then
        do {
            let key = try ConfigurationManager.supabaseKey
            XCTAssertNotNil(key, "Supabase key should be configured")
            XCTAssertFalse(key.isEmpty, "Supabase key should not be empty")
        } catch ConfigurationError.missingKey(let keyName) {
            // Expected in test environment without proper Info.plist
            XCTAssertEqual(keyName, "SUPABASE_KEY")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfigurationErrorDescription() {
        // Given
        let missingKeyError = ConfigurationError.missingKey("TEST_KEY")
        let invalidValueError = ConfigurationError.invalidValue("TEST_VALUE")

        // Then
        XCTAssertTrue(missingKeyError.errorDescription?.contains("TEST_KEY") ?? false)
        XCTAssertTrue(invalidValueError.errorDescription?.contains("TEST_VALUE") ?? false)
    }
}
