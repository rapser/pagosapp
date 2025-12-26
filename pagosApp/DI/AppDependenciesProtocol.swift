//
//  AppDependenciesProtocol.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

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
