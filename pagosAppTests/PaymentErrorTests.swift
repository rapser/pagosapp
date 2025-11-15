//
//  PaymentErrorTests.swift
//  pagosAppTests
//
//  Unit tests for PaymentError
//

import XCTest
@testable import pagosApp

final class PaymentErrorTests: XCTestCase {

    func testInvalidAmountError() {
        // Given
        let error = PaymentError.invalidAmount

        // Then
        XCTAssertEqual(error.title, "Monto Inválido")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertEqual(error.severity, .warning)
    }

    func testInvalidDateError() {
        // Given
        let error = PaymentError.invalidDate

        // Then
        XCTAssertEqual(error.title, "Fecha Inválida")
        XCTAssertEqual(error.severity, .warning)
    }

    func testSaveFailedError() {
        // Given
        let underlyingError = NSError(domain: "TestError", code: 1, userInfo: nil)
        let error = PaymentError.saveFailed(underlyingError)

        // Then
        XCTAssertEqual(error.title, "Error al Guardar")
        XCTAssertEqual(error.severity, .error)
        XCTAssertNotNil(error.errorDescription)
    }

    func testNotificationScheduleFailedError() {
        // Given
        let underlyingError = NSError(domain: "TestError", code: 2, userInfo: nil)
        let error = PaymentError.notificationScheduleFailed(underlyingError)

        // Then
        XCTAssertEqual(error.title, "Error de Notificación")
        XCTAssertEqual(error.severity, .warning)
        XCTAssertTrue(error.recoverySuggestion?.contains("notificaciones") ?? false)
    }

    func testCalendarSyncFailedError() {
        // Given
        let underlyingError = NSError(domain: "TestError", code: 3, userInfo: nil)
        let error = PaymentError.calendarSyncFailed(underlyingError)

        // Then
        XCTAssertEqual(error.title, "Error de Calendario")
        XCTAssertEqual(error.severity, .warning)
        XCTAssertTrue(error.recoverySuggestion?.contains("calendario") ?? false)
    }
}
