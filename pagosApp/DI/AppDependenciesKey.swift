//
//  AppDependenciesKey.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import SwiftUI

/// Environment key for dependency injection
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
