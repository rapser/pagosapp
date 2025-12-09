//
//  AppDependencies.swift
//  pagosApp
//
//  Dependency Injection Container
//  Manages app-wide dependencies and eliminates Singleton pattern
//  Created by Claude Code - Fase 2 Technical Debt Reduction
//

import Foundation
import SwiftData
import Supabase
import Observation
import SwiftUI

/// Protocol defining all app dependencies
/// This allows for easy testing with mock implementations
@MainActor
protocol AppDependenciesProtocol {
    var settingsManager: SettingsManager { get }
    var paymentSyncManager: PaymentSyncManager { get }
    var errorHandler: ErrorHandler { get }
    var authenticationManager: AuthenticationManager { get }
    var biometricManager: BiometricManager { get }
    var sessionManager: SessionManager { get }
    var notificationManager: NotificationManager { get }
    var eventKitManager: EventKitManager { get }
    var alertManager: AlertManager { get }
    var storageFactory: StorageFactory { get }
}

/// Concrete implementation of app dependencies
/// This is the production DI container
@MainActor
@Observable
final class AppDependencies: AppDependenciesProtocol {
    // MARK: - Dependencies

    let settingsManager: SettingsManager
    let paymentSyncManager: PaymentSyncManager
    let errorHandler: ErrorHandler
    let authenticationManager: AuthenticationManager
    let biometricManager: BiometricManager
    let sessionManager: SessionManager
    let notificationManager: NotificationManager
    let eventKitManager: EventKitManager
    let alertManager: AlertManager
    let storageFactory: StorageFactory

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        supabaseClient: SupabaseClient
    ) {
        // Initialize managers in dependency order
        self.errorHandler = ErrorHandler()
        self.settingsManager = SettingsManager()
        self.biometricManager = BiometricManager()
        self.sessionManager = SessionManager()
        self.notificationManager = NotificationManager()
        self.eventKitManager = EventKitManager(errorHandler: errorHandler)
        self.alertManager = AlertManager()

        // Initialize StorageFactory with configuration
        let storageConfig = StorageConfiguration.supabase(
            client: supabaseClient,
            modelContext: modelContext
        )
        self.storageFactory = StorageFactory(configuration: storageConfig)

        // Initialize PaymentSyncManager before AuthenticationManager (dependency order)
        self.paymentSyncManager = PaymentSyncManager(
            errorHandler: errorHandler
        )

        // Initialize AuthenticationManager with all its dependencies
        let authAdapter = SupabaseAuthAdapter(client: supabaseClient)
        let authRepository = AuthRepository(authService: authAdapter)
        self.authenticationManager = AuthenticationManager(
            authRepository: authRepository,
            errorHandler: errorHandler,
            settingsManager: settingsManager,
            paymentSyncManager: paymentSyncManager
        )
    }

    // MARK: - Convenience Initializer for Testing

    static func mock() -> AppDependencies {
        // For testing - create mock container with test dependencies
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Payment.self, UserProfile.self, configurations: config)
        let mockSupabase = SupabaseClient(
            supabaseURL: URL(string: "https://mock.supabase.co")!,
            supabaseKey: "mock_key"
        )
        return AppDependencies(
            modelContext: container.mainContext,
            supabaseClient: mockSupabase
        )
    }
}

// MARK: - Environment Key

/// Environment key for dependency injection
struct AppDependenciesKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AppDependencies = .mock()
}

extension EnvironmentValues {
    var dependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
