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
        self.errorHandler = ErrorHandler()
        self.settingsManager = SettingsManager()
        self.biometricManager = BiometricManager()
        self.sessionManager = SessionManager()
        self.notificationManager = NotificationManager()
        self.eventKitManager = EventKitManager(errorHandler: errorHandler)
        self.alertManager = AlertManager()

        let storageConfig = StorageConfiguration.supabase(
            client: supabaseClient,
            modelContext: modelContext
        )
        self.storageFactory = StorageFactory(configuration: storageConfig)

        self.paymentSyncManager = PaymentSyncManager(
            errorHandler: errorHandler
        )

        let authAdapter = SupabaseAuthAdapter(client: supabaseClient)
        let authRepository = AuthRepository(authService: authAdapter)
        self.authenticationManager = AuthenticationManager(
            authRepository: authRepository,
            errorHandler: errorHandler,
            settingsManager: settingsManager,
            paymentSyncManager: paymentSyncManager
        )

        self.paymentSyncManager.setAuthRepository(authRepository)
        self.paymentSyncManager.setNotificationManager(notificationManager)
    }

    // MARK: - Convenience Initializer for Testing

    static func mock() -> AppDependencies {
        
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
