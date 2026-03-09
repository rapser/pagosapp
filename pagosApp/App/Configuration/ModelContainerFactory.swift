//
//  ModelContainerFactory.swift
//  pagosApp
//
//  Factory for creating SwiftData ModelContainer instances.
//  Un solo store (pagos, perfil, recordatorios). No se modifica lógica de pagos.
//

import Foundation
import SwiftData
import OSLog

/// Factory responsible for creating and configuring SwiftData ModelContainer
enum ModelContainerFactory {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ModelContainerFactory")

    /// Creates a configured ModelContainer for the app's data models (pagos, perfil, recordatorios).
    static func create() -> ModelContainer {
        let schema = Schema([PaymentLocalDTO.self, UserProfileLocalDTO.self, ReminderLocalDTO.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("\(L10n.Log.Db.modelContainerFailed(error.localizedDescription))")
            return recoverFromCorruption(schema: schema, configuration: modelConfiguration)
        }
    }

    private static func recoverFromCorruption(schema: Schema, configuration: ModelConfiguration) -> ModelContainer {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("\(L10n.Log.Db.recoveryFailed(error.localizedDescription))")
            fatalError("Could not initialize SwiftData container: \(error)")
        }
    }
}
