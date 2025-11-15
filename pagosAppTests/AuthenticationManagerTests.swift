//
//  AuthenticationManagerTests.swift
//  pagosAppTests
//
//  Unit tests for AuthenticationManager
//

import XCTest
@testable import pagosApp
import Combine

@MainActor
final class AuthenticationManagerTests: XCTestCase {
    var sut: AuthenticationManager!
    var mockAuthService: MockAuthenticationService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthenticationService()
        sut = AuthenticationManager(authService: mockAuthService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        sut = nil
        mockAuthService = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Login Tests

    func testLoginWithValidCredentials() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true

        // When
        let error = await sut.login(email: email, password: password)

        // Then
        XCTAssertNil(error, "Login should succeed with valid credentials")
        XCTAssertTrue(sut.hasLoggedInWithCredentials, "hasLoggedInWithCredentials should be true")
    }

    func testLoginWithInvalidEmail() async throws {
        // Given
        let invalidEmail = "invalid-email"
        let password = "password123"

        // When
        let error = await sut.login(email: invalidEmail, password: password)

        // Then
        XCTAssertNotNil(error, "Login should fail with invalid email")
        if case .invalidEmailFormat = error {
            // Success
        } else {
            XCTFail("Expected invalidEmailFormat error")
        }
    }

    func testLoginWithWrongCredentials() async throws {
        // Given
        let email = "test@example.com"
        let password = "wrongpassword"
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = .wrongCredentials

        // When
        let error = await sut.login(email: email, password: password)

        // Then
        XCTAssertNotNil(error, "Login should fail with wrong credentials")
        if case .wrongCredentials = error {
            // Success
        } else {
            XCTFail("Expected wrongCredentials error")
        }
    }

    func testLoginSetsLoadingState() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true
        mockAuthService.delaySeconds = 0.5

        var loadingStates: [Bool] = []
        sut.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        // When
        _ = await sut.login(email: email, password: password)

        // Then
        XCTAssertTrue(loadingStates.contains(true), "isLoading should be true during login")
        XCTAssertFalse(sut.isLoading, "isLoading should be false after login")
    }

    // MARK: - Registration Tests

    func testRegisterWithValidCredentials() async throws {
        // Given
        let email = "newuser@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true

        // When
        let error = await sut.register(email: email, password: password)

        // Then
        XCTAssertNil(error, "Registration should succeed with valid credentials")
        XCTAssertTrue(sut.hasLoggedInWithCredentials, "hasLoggedInWithCredentials should be true")
    }

    func testRegisterWithInvalidEmail() async throws {
        // Given
        let invalidEmail = "invalid"
        let password = "password123"

        // When
        let error = await sut.register(email: invalidEmail, password: password)

        // Then
        XCTAssertNotNil(error, "Registration should fail with invalid email")
        if case .invalidEmailFormat = error {
            // Success
        } else {
            XCTFail("Expected invalidEmailFormat error")
        }
    }

    // MARK: - Logout Tests

    func testLogout() async throws {
        // Given
        mockAuthService.shouldSucceed = true
        _ = await sut.login(email: "test@example.com", password: "password123")

        // When
        await sut.logout()

        // Then
        XCTAssertFalse(sut.hasLoggedInWithCredentials, "hasLoggedInWithCredentials should be false after logout")
    }
}

// MARK: - Mock Authentication Service

class MockAuthenticationService: AuthenticationService {
    var shouldSucceed = true
    var errorToThrow: AuthenticationError = .wrongCredentials
    var delaySeconds: TimeInterval = 0
    var isAuthenticatedValue = false

    private let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)

    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        _isAuthenticatedSubject.eraseToAnyPublisher()
    }

    var isAuthenticated: Bool {
        isAuthenticatedValue
    }

    func signIn(email: String, password: String) async throws {
        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        if shouldSucceed {
            isAuthenticatedValue = true
            _isAuthenticatedSubject.send(true)
        } else {
            throw errorToThrow
        }
    }

    func signOut() async throws {
        if shouldSucceed {
            isAuthenticatedValue = false
            _isAuthenticatedSubject.send(false)
        } else {
            throw errorToThrow
        }
    }

    func getCurrentUser() async throws -> String? {
        return shouldSucceed ? "test@example.com" : nil
    }

    func signUp(email: String, password: String) async throws {
        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        if shouldSucceed {
            isAuthenticatedValue = true
            _isAuthenticatedSubject.send(true)
        } else {
            throw errorToThrow
        }
    }
}
