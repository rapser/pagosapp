//
//  pagosAppApp.swift
//  pagosApp
//
//  Main app entry point
//  Orchestrates app initialization and dependency injection
//

import SwiftUI

@main
struct PagosAppApp: App {
    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
        }
    }
}
