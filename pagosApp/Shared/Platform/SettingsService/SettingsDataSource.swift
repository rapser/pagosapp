//
//  SettingsDataSource.swift
//  pagosApp
//
//  Platform DataSource for app-wide settings storage
//  Clean Architecture - Data Layer (Platform)
//

import Foundation

/// Protocol for settings storage operations
protocol SettingsDataSource {
    /// Check if biometric lock is enabled
    var isBiometricLockEnabled: Bool { get set }
}

/// UserDefaults implementation of SettingsDataSource
final class UserDefaultsSettingsDataSource: SettingsDataSource {
    private let userDefaults: UserDefaults
    private let biometricLockKey = "isBiometricLockEnabled"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isBiometricLockEnabled: Bool {
        get {
            userDefaults.bool(forKey: biometricLockKey)
        }
        set {
            userDefaults.set(newValue, forKey: biometricLockKey)
        }
    }
}
