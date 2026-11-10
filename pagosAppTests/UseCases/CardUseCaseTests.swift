//
//  CardUseCaseTests.swift
//  pagosAppTests
//
//  Unit tests for the two-step (number, then PIN) card reveal flow.
//

import Foundation
import LocalAuthentication
import Testing
@testable import pagosApp

// MARK: - Mocks

@MainActor
final class MockBiometricRepository: BiometricRepositoryProtocol {
    var shouldSucceed = true
    private(set) var authenticateCallCount = 0
    private(set) var reasons: [String] = []

    var isBiometricAvailable: Bool { get async { true } }
    var biometricType: BiometricType { get async { .faceID } }

    func authenticateWithBiometric(reason: String) async -> Result<Bool, AuthError> {
        authenticateCallCount += 1
        reasons.append(reason)
        return shouldSucceed ? .success(true) : .failure(.unknown("cancelled"))
    }

    func authenticateWithBiometricContext(reason: String) async -> Result<LAContext, AuthError> {
        authenticateCallCount += 1
        reasons.append(reason)
        return shouldSucceed ? .success(LAContext()) : .failure(.unknown("cancelled"))
    }

    func canUseBiometrics() async -> Bool { true }
}

@MainActor
final class MockCreditCardRepository: CreditCardRepositoryProtocol {
    var cardNumber: String? = "4111111111111111"
    var pin: String? = "1234"
    private(set) var numberReadCount = 0
    private(set) var pinReadCount = 0

    func getAllCards() async throws -> [CreditCard] { [] }
    func saveCard(_ card: CreditCard, cardNumber: String, pin: String) async throws {}
    func deleteCard(id: UUID) async throws {}

    func revealSensitiveData(cardId: UUID, context: LAContext?) async throws -> CreditCardSensitiveData {
        let number = try await revealCardNumber(cardId: cardId, context: context)
        let pin = try await revealPin(cardId: cardId, context: context)
        return CreditCardSensitiveData(cardNumber: number, pin: pin)
    }

    func revealCardNumber(cardId: UUID, context: LAContext?) async throws -> String {
        numberReadCount += 1
        guard let cardNumber else { throw CardError.notFound }
        return cardNumber
    }

    func revealPin(cardId: UUID, context: LAContext?) async throws -> String {
        pinReadCount += 1
        guard let pin else { throw CardError.notFound }
        return pin
    }
}

// MARK: - RevealCreditCardSensitiveDataUseCase

@Suite("RevealCreditCardSensitiveDataUseCase")
@MainActor
struct RevealCreditCardSensitiveDataUseCaseTests {
    let biometric = MockBiometricRepository()
    let repository = MockCreditCardRepository()

    var sut: RevealCreditCardSensitiveDataUseCase {
        RevealCreditCardSensitiveDataUseCase(
            cardRepository: repository,
            biometricRepository: biometric,
            log: NullLog()
        )
    }

    @Test func executeCardNumber_success_returnsNumberWithoutReadingPin() async {
        let result = await sut.executeCardNumber(cardId: UUID(), reason: "number")

        #expect(result == .success("4111111111111111"))
        #expect(biometric.authenticateCallCount == 1)
        #expect(repository.numberReadCount == 1)
        #expect(repository.pinReadCount == 0)
    }

    @Test func executeCardNumber_biometricFails_doesNotReadKeychain() async {
        biometric.shouldSucceed = false

        let result = await sut.executeCardNumber(cardId: UUID(), reason: "number")

        #expect(result == .failure(.biometricFailed))
        #expect(repository.numberReadCount == 0)
        #expect(repository.pinReadCount == 0)
    }

    @Test func executePin_success_returnsPinWithoutReadingNumber() async {
        let result = await sut.executePin(cardId: UUID(), reason: "pin")

        #expect(result == .success("1234"))
        #expect(repository.pinReadCount == 1)
        #expect(repository.numberReadCount == 0)
    }

    @Test func executePin_biometricFails_doesNotReadPin() async {
        biometric.shouldSucceed = false

        let result = await sut.executePin(cardId: UUID(), reason: "pin")

        #expect(result == .failure(.biometricFailed))
        #expect(repository.pinReadCount == 0)
    }

    @Test func numberThenPin_requiresTwoSeparateBiometricChecks() async {
        let useCase = sut
        _ = await useCase.executeCardNumber(cardId: UUID(), reason: "number")
        _ = await useCase.executePin(cardId: UUID(), reason: "pin")

        #expect(biometric.authenticateCallCount == 2)
        #expect(biometric.reasons == ["number", "pin"])
    }

    @Test func executePin_missingKeychainItem_returnsBiometricFailed() async {
        repository.pin = nil

        let result = await sut.executePin(cardId: UUID(), reason: "pin")

        #expect(result == .failure(.biometricFailed))
    }
}
