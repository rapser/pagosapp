//
//  SettingsStore.swift
//  pagosApp
//
//  Observable store for app settings (Presentation layer wrapper)
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation

/// Observable store for app-wide settings
/// Wraps SettingsDataSource for SwiftUI compatibility
@MainActor
@Observable
final class SettingsStore {
    private var dataSource: SettingsDataSource

    var isBiometricLockEnabled: Bool {
        get { dataSource.isBiometricLockEnabled }
        set { dataSource.isBiometricLockEnabled = newValue }
    }

    init(dataSource: SettingsDataSource) {
        self.dataSource = dataSource
    }
}
