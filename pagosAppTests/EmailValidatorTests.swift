//
//  EmailValidatorTests.swift
//  pagosAppTests
//

import Testing
@testable import pagosApp

struct EmailValidatorTests {

    @Test func acceptsValidEmail() throws {
        #expect(EmailValidator.isValid("user@example.com"))
        try EmailValidator.validate("user@example.com")
    }

    @Test func rejectsMissingAt() {
        #expect(EmailValidator.isValid("userexample.com") == false)
        #expect(throws: AuthError.invalidEmail) {
            try EmailValidator.validate("userexample.com")
        }
    }

    @Test func rejectsMissingDomain() {
        #expect(EmailValidator.isValid("user@") == false)
    }
}
