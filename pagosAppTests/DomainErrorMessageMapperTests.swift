//
//  DomainErrorMessageMapperTests.swift
//  pagosAppTests
//
//  Ensures every domain error case maps to a non-empty, stable user-facing string.
//

import Foundation
import Testing
@testable import pagosApp

struct DomainErrorMessageMapperTests {

    @Test func paymentErrorMapperCoversAllCasesWithNonEmptyMessages() {
        let cases: [PaymentError] = [
            .invalidName,
            .invalidAmount,
            .invalidDate,
            .saveFailed("e"),
            .deleteFailed("e"),
            .updateFailed("e"),
            .notificationScheduleFailed("e"),
            .calendarSyncFailed("e"),
            .notFound,
            .unknown("e")
        ]
        for pe in cases {
            let s = PaymentErrorMessageMapper.message(for: pe)
            #expect(!s.isEmpty, "Empty message for \(pe)")
        }
    }

    @Test func authErrorMapperCoversAllCasesWithNonEmptyMessages() {
        let until = Date(timeIntervalSince1970: 1_800_000_000)
        let cases: [AuthError] = [
            .invalidCredentials,
            .emailAlreadyExists,
            .weakPassword,
            .invalidEmail,
            .userNotFound,
            .sessionExpired,
            .networkError("offline"),
            .unknown("x"),
            .tooManyLoginAttempts(lockoutUntil: until)
        ]
        for ae in cases {
            let s = AuthErrorMessageMapper.message(for: ae)
            #expect(!s.isEmpty, "Empty message for \(ae)")
        }
    }
}
