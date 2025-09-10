//
//  pagosAppApp.swift
//  pagosApp
//
//  Created by miguel tomairo on 5/09/25.
//

import SwiftUI
import SwiftData
import Supabase

let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://jmkzwdacjwjezkalpfbl.supabase.co")!,
    supabaseKey: "sb_publishable_q-Hns6a3-nBszokYo5euLQ_u0uyqN53"
)

@main
struct pagosAppApp: App {
    private let supabaseAuthService = SupabaseAuthService(client: supabaseClient)
    private let authenticationManager: AuthenticationManager

    init() {
        authenticationManager = AuthenticationManager(authService: supabaseAuthService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationManager)
                .tint(Color("AppPrimary"))
        }
        .modelContainer(for: Payment.self)
    }
}
