//
//  pagosAppApp.swift
//  pagosApp
//
//  Created by miguel tomairo on 5/09/25.
//

import SwiftUI
import SwiftData

@main
struct pagosAppApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Configuramos el contenedor de SwiftData para el modelo Payment.
        // Esto inyecta el modelContext en el entorno de la app.
        .modelContainer(for: Payment.self)
    }
}
