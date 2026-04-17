//
//  PasswordValidatorTests.swift
//  pagosAppTests
//

import Testing
@testable import pagosApp

struct PasswordValidatorTests {

    @Test func rejectsTooShort() {
        #expect(PasswordValidator.isValid("Aa1!") == false)
    }

    @Test func rejectsMissingUppercase() {
        #expect(PasswordValidator.isValid("aa1!aaaa") == false)
    }

    @Test func acceptsStrongPassword() throws {
        let pwd = "Aa1!aaaa"
        #expect(PasswordValidator.isValid(pwd))
        try PasswordValidator.validate(pwd)
    }
}
