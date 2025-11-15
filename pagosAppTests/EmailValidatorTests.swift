//
//  EmailValidatorTests.swift
//  pagosAppTests
//
//  Unit tests for EmailValidator
//

import XCTest
@testable import pagosApp

final class EmailValidatorTests: XCTestCase {

    func testValidEmails() {
        // Given
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "test123@test-domain.com",
            "a@b.co"
        ]

        // When/Then
        for email in validEmails {
            XCTAssertTrue(EmailValidator.isValidEmail(email), "\(email) should be valid")
        }
    }

    func testInvalidEmails() {
        // Given
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            "user @example.com",
            "user@domain",
            "",
            "user@@example.com",
            "user@.com"
        ]

        // When/Then
        for email in invalidEmails {
            XCTAssertFalse(EmailValidator.isValidEmail(email), "\(email) should be invalid")
        }
    }

    func testEmailWithSpaces() {
        // Given
        let emailWithSpaces = " test@example.com "

        // When
        let isValid = EmailValidator.isValidEmail(emailWithSpaces)

        // Then
        XCTAssertFalse(isValid, "Email with leading/trailing spaces should be invalid")
    }

    func testEmptyEmail() {
        // Given
        let emptyEmail = ""

        // When
        let isValid = EmailValidator.isValidEmail(emptyEmail)

        // Then
        XCTAssertFalse(isValid, "Empty email should be invalid")
    }
}
