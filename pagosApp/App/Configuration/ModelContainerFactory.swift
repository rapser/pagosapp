//
//  ModelContainerFactory.swift
//  pagosApp
//
//  Factory for creating SwiftData ModelContainer instances
//  Infrastructure Layer - Persistence Configuration
//

import Foundation
import SwiftData
import OSLog

/// Factory responsible for creating and configuring SwiftData ModelContainer
enum ModelContainerFactory {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ModelContainerFactory")

    /// Creates a configured ModelContainer for the app's data models
    /// Implements automatic recovery on database corruption
    static func create() -> ModelContainer {
        let schema = Schema([PaymentLocalDTO.self, UserProfileLocalDTO.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("❌ Failed to create ModelContainer: \(error.localizedDescription)")

            // Attempt database recovery
            return recoverFromCorruption(schema: schema, configuration: modelConfiguration)
        }
    }

    /// Attempts to recover from database corruption by recreating the database
    private static func recoverFromCorruption(schema: Schema, configuration: ModelConfiguration) -> ModelContainer {
        logger.warning("⚠️ Attempting database recovery...")

        // Remove corrupted database files
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")

            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))

            logger.info("🗑️ Corrupted database files removed")
        }

        // Attempt to create new container
        do {
            let newContainer = try ModelContainer(for: schema, configurations: [configuration])
            logger.info("✅ Database successfully recreated")
            return newContainer
        } catch {
            logger.error("❌ Fatal: Could not recover database: \(error.localizedDescription)")
            fatalError("Could not initialize SwiftData container: \(error)")
        }
    }
}
