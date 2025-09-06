//
//  pagosAppApp.swift
//  pagosApp
//
//  Created by miguel tomairo on 5/09/25.
//

import SwiftUI
import SwiftData
import Supabase

// Initialize Supabase client globally or as a static property
let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://jmkzwdacjwjezkalpfbl.supabase.co")!,
    supabaseKey: "sb_publishable_q-Hns6a3-nBszokYo5euLQ_u0uyqN53"
)

@main
struct pagosAppApp: App {
    // Initialize SupabaseAuthService and AuthenticationManager
    private let supabaseAuthService = SupabaseAuthService(client: supabaseClient)
    private let authenticationManager: AuthenticationManager

    init() {
        authenticationManager = AuthenticationManager(authService: supabaseAuthService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationManager)
        }
        // Configuramos el contenedor de SwiftData para el modelo Payment.
        // Esto inyecta el modelContext en el entorno de la app.
        .modelContainer(for: Payment.self)
    }
}
