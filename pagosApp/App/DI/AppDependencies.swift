//
//  AppDependencies.swift
//  pagosApp
//
//  Dependency Injection Container
//  Orchestrates feature containers following Clean Architecture
//

import Foundation
import SwiftData
import Observation
import SwiftUI
import Supabase

/// App-wide dependency injection orchestrator
/// Delegates to feature-specific DI containers (Clean Architecture)
@MainActor
@Observable
final class AppDependencies {
    // MARK: - Platform Services (Shared Infrastructure)

    let settingsStore: SettingsStore
    let errorHandler: ErrorHandler
    let notificationDataSource: NotificationDataSource
    let calendarEventDataSource: CalendarEventDataSource
    let alertManager: AlertManager

    // MARK: - Feature Containers (Clean Architecture)

    let authDependencyContainer: AuthDependencyContainer
    let paymentDependencyContainer: PaymentDependencyContainer
    let userProfileDependencyContainer: UserProfileDependencyContainer
    let calendarDependencyContainer: CalendarDependencyContainer
    let statisticsDependencyContainer: StatisticsDependencyContainer
    let historyDependencyContainer: HistoryDependencyContainer
    let settingsDependencyContainer: SettingsDependencyContainer

    // MARK: - Coordinators (Created by Containers)

    let sessionCoordinator: SessionCoordinator
    let paymentSyncCoordinator: PaymentSyncCoordinator

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        supabaseClient: SupabaseClient
    ) {
        self.errorHandler = ErrorHandler()

        // Platform DataSources (Infrastructure)
        let settingsDataSource = UserDefaultsSettingsDataSource()
        self.settingsStore = SettingsStore(dataSource: settingsDataSource)
        self.notificationDataSource = UserNotificationsDataSource()
        self.calendarEventDataSource = EventKitCalendarDataSource()
        self.alertManager = AlertManager()

        // Feature Dependency Containers (Clean Architecture)
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

        self.historyDependencyContainer = HistoryDependencyContainer(
            paymentDependencyContainer: paymentDependencyContainer
        )

        // Coordinators (Created by feature containers)
        self.paymentSyncCoordinator = paymentDependencyContainer.makePaymentSyncCoordinator()

        self.sessionCoordinator = authDependencyContainer.makeSessionCoordinator(
            errorHandler: errorHandler,
            settingsStore: settingsStore,
            paymentSyncCoordinator: paymentSyncCoordinator
        )

        self.settingsDependencyContainer = SettingsDependencyContainer(
            paymentSyncCoordinator: paymentSyncCoordinator,
            authDependencyContainer: authDependencyContainer,
            userProfileDependencyContainer: userProfileDependencyContainer
        )
    }

    // MARK: - Mock for Testing/Previews

    static func mock() -> AppDependencies {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: PaymentEntity.self, UserProfile.self, configurations: config)
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
