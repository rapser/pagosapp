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
    let errorHandler: ErrorHandler
    let authenticationManager: AuthenticationManager
    let notificationManager: NotificationManager
    let eventKitManager: EventKitManager
    let alertManager: AlertManager
    let supabaseClient: SupabaseClient

    // MARK: - Feature Containers (Clean Architecture)
    let authDependencyContainer: AuthDependencyContainer
    let paymentDependencyContainer: PaymentDependencyContainer
    let userProfileDependencyContainer: UserProfileDependencyContainer
    let calendarDependencyContainer: CalendarDependencyContainer
    let statisticsDependencyContainer: StatisticsDependencyContainer

    // MARK: - Coordinators
    let paymentSyncCoordinator: PaymentSyncCoordinator

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        supabaseClient: SupabaseClient
    ) {
        self.supabaseClient = supabaseClient
        self.errorHandler = ErrorHandler()
        self.settingsManager = SettingsManager()
        self.notificationManager = NotificationManager()
        self.eventKitManager = EventKitManager(errorHandler: errorHandler)
        self.alertManager = AlertManager()

        // Create Feature Dependency Containers (Clean Architecture)
        self.authDependencyContainer = AuthDependencyContainer(supabaseClient: supabaseClient)
        self.paymentDependencyContainer = PaymentDependencyContainer(
            supabaseClient: supabaseClient,
            modelContext: modelContext
        )
        self.userProfileDependencyContainer = UserProfileDependencyContainer(
            supabaseClient: supabaseClient,
            modelContext: modelContext
        )
        self.calendarDependencyContainer = CalendarDependencyContainer(
            paymentDependencyContainer: paymentDependencyContainer
        )
        self.statisticsDependencyContainer = StatisticsDependencyContainer(
            paymentDependencyContainer: paymentDependencyContainer
        )

        // Create Coordinators from containers
        self.paymentSyncCoordinator = paymentDependencyContainer.makePaymentSyncCoordinator()

        // Legacy AuthRepository for compatibility (to be removed in future phases)
        let authAdapter = SupabaseAuthAdapter(client: supabaseClient)
        let authRepository = AuthRepository(authService: authAdapter)

        // AuthenticationManager now uses Use Cases via AuthDependencyContainer
        self.authenticationManager = AuthenticationManager(
            authRepository: authRepository,
            errorHandler: errorHandler,
            settingsManager: settingsManager,
            paymentSyncCoordinator: paymentSyncCoordinator,
            authDependencyContainer: authDependencyContainer
        )
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
