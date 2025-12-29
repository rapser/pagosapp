//
//  AppDependencies.swift
//  pagosApp
//
//  Dependency Injection Container
//  Manages app-wide dependencies and eliminates Singleton pattern
//

import Foundation
import SwiftData
import Supabase
import Observation
import SwiftUI

/// App-wide dependency injection container
@MainActor
@Observable
final class AppDependencies {
    // MARK: - Dependencies

    let settingsStore: SettingsStore
    let errorHandler: ErrorHandler
    let sessionCoordinator: SessionCoordinator
    let notificationDataSource: NotificationDataSource
    let calendarEventDataSource: CalendarEventDataSource
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

        // Platform DataSources
        let settingsDataSource = UserDefaultsSettingsDataSource()
        self.settingsStore = SettingsStore(dataSource: settingsDataSource)
        self.notificationDataSource = UserNotificationsDataSource()
        self.calendarEventDataSource = EventKitCalendarDataSource()

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
            paymentDependencyContainer: paymentDependencyContainer,
            calendarEventDataSource: calendarEventDataSource
        )
        self.statisticsDependencyContainer = StatisticsDependencyContainer(
            paymentDependencyContainer: paymentDependencyContainer
        )

        // Create Coordinators from containers
        self.paymentSyncCoordinator = paymentDependencyContainer.makePaymentSyncCoordinator()

        // Legacy AuthRepository for compatibility (to be removed in future phases)
        let authAdapter = SupabaseAuthAdapter(client: supabaseClient)
        let authRepository = AuthRepository(authService: authAdapter)

        // SessionCoordinator manages session lifecycle using Use Cases
        self.sessionCoordinator = SessionCoordinator(
            authRepository: authRepository,
            errorHandler: errorHandler,
            settingsStore: settingsStore,
            paymentSyncCoordinator: paymentSyncCoordinator,
            authDependencyContainer: authDependencyContainer
        )
    }

    // MARK: - Mock for Testing/Previews

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

// MARK: - Environment Key

/// SwiftUI Environment key for dependency injection
struct AppDependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: AppDependencies = .mock()
}

extension EnvironmentValues {
    var dependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
