//
//  AppDependenciesProtocol.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import Supabase

/// Protocol defining all app dependencies
/// This allows for easy testing with mock implementations
@MainActor
protocol AppDependenciesProtocol {
    var settingsStore: SettingsStore { get }
    var errorHandler: ErrorHandler { get }
    var authenticationManager: AuthenticationManager { get }
    var notificationDataSource: NotificationDataSource { get }
    var calendarEventDataSource: CalendarEventDataSource { get }
    var alertManager: AlertManager { get }
    var supabaseClient: SupabaseClient { get }

    // Feature Containers (Clean Architecture)
    var authDependencyContainer: AuthDependencyContainer { get }
    var paymentDependencyContainer: PaymentDependencyContainer { get }
    var userProfileDependencyContainer: UserProfileDependencyContainer { get }
    var calendarDependencyContainer: CalendarDependencyContainer { get }
    var statisticsDependencyContainer: StatisticsDependencyContainer { get }

    // Coordinators
    var paymentSyncCoordinator: PaymentSyncCoordinator { get }
}
