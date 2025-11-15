//
//  PaymentDTOTests.swift
//  pagosAppTests
//
//  Unit tests for PaymentDTO
//

import XCTest
@testable import pagosApp

final class PaymentDTOTests: XCTestCase {

    func testPaymentToDTO() {
        // Given
        let payment = Payment(
            name: "Test Payment",
            amount: 100.50,
            dueDate: Date(),
            isPaid: false,
            category: .recibo
        )
        let userId = UUID()

        // When
        let dto = payment.toDTO(userId: userId)

        // Then
        XCTAssertEqual(dto.id, payment.id)
        XCTAssertEqual(dto.userId, userId)
        XCTAssertEqual(dto.name, payment.name)
        XCTAssertEqual(dto.amount, payment.amount)
        XCTAssertEqual(dto.dueDate, payment.dueDate)
        XCTAssertEqual(dto.isPaid, payment.isPaid)
        XCTAssertEqual(dto.category, payment.category.rawValue)
    }

    func testDTOToPayment() {
        // Given
        let userId = UUID()
        let paymentId = UUID()
        let dueDate = Date()

        let json = """
        {
            "id": "\(paymentId.uuidString)",
            "user_id": "\(userId.uuidString)",
            "name": "Test Payment",
            "amount": 150.75,
            "due_date": "\(ISO8601DateFormatter().string(from: dueDate))",
            "is_paid": true,
            "category": "Suscripción",
            "event_identifier": "event123",
            "created_at": "\(ISO8601DateFormatter().string(from: Date()))",
            "updated_at": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """.data(using: .utf8)!

        // When
        let dto = try? JSONDecoder().decode(PaymentDTO.self, from: json)
        let payment = dto?.toPayment()

        // Then
        XCTAssertNotNil(dto)
        XCTAssertNotNil(payment)
        XCTAssertEqual(payment?.id, paymentId)
        XCTAssertEqual(payment?.name, "Test Payment")
        XCTAssertEqual(payment?.amount, 150.75)
        XCTAssertEqual(payment?.isPaid, true)
        XCTAssertEqual(payment?.category, .suscripcion)
        XCTAssertEqual(payment?.eventIdentifier, "event123")
    }

    func testDTOEncodingDecoding() throws {
        // Given
        let userId = UUID()
        let payment = Payment(
            name: "Encoded Payment",
            amount: 200.00,
            dueDate: Date(),
            isPaid: false,
            category: .tarjetaCredito
        )
        let dto = payment.toDTO(userId: userId)

        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(dto)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PaymentDTO.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.id, dto.id)
        XCTAssertEqual(decoded.name, dto.name)
        XCTAssertEqual(decoded.amount, dto.amount)
        XCTAssertEqual(decoded.category, dto.category)
    }

    func testAllPaymentCategories() {
        // Given
        let categories: [PaymentCategory] = [.recibo, .tarjetaCredito, .ahorro, .suscripcion, .otro]
        let userId = UUID()

        // When/Then
        for category in categories {
            let payment = Payment(
                name: "Test",
                amount: 100,
                dueDate: Date(),
                isPaid: false,
                category: category
            )
            let dto = payment.toDTO(userId: userId)
            let convertedBack = dto.toPayment()

            XCTAssertEqual(convertedBack.category, category, "Category \(category.rawValue) should convert correctly")
        }
    }

    func testInvalidCategoryFallsBackToOtro() {
        // Given
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "user_id": "\(UUID().uuidString)",
            "name": "Test",
            "amount": 100,
            "due_date": "\(ISO8601DateFormatter().string(from: Date()))",
            "is_paid": false,
            "category": "Invalid Category"
        }
        """.data(using: .utf8)!

        // When
        let dto = try? JSONDecoder().decode(PaymentDTO.self, from: json)
        let payment = dto?.toPayment()

        // Then
        XCTAssertNotNil(payment)
        XCTAssertEqual(payment?.category, .otro, "Invalid category should fallback to 'otro'")
    }
}
