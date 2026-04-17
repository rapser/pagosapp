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

struct ModelContainerCreationResult: Sendable {
    let container: ModelContainer?
    let didFallbackToInMemory: Bool
    let failureDescription: String?
}

/// Factory responsible for creating and configuring SwiftData ModelContainer
enum ModelContainerFactory {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ModelContainerFactory")

    /// Creates a configured ModelContainer for the app's data models (pagos, perfil, recordatorios).
    static func create() -> ModelContainerCreationResult {
        let schema = Schema([PaymentLocalDTO.self, UserProfileLocalDTO.self, ReminderLocalDTO.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return ModelContainerCreationResult(
                container: container,
                didFallbackToInMemory: false,
                failureDescription: nil
            )
        } catch {
            logger.error("\(L10n.Log.Db.modelContainerFailed(error.localizedDescription))")
            return fallbackToInMemoryContainer(schema: schema, underlyingError: error)
        }
    }

    private static func fallbackToInMemoryContainer(schema: Schema, underlyingError: Error) -> ModelContainerCreationResult {
        do {
            let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            return ModelContainerCreationResult(
                container: container,
                didFallbackToInMemory: true,
                failureDescription: underlyingError.localizedDescription
            )
        } catch {
            logger.error("\(L10n.Log.Db.recoveryFailed(error.localizedDescription))")
            return ModelContainerCreationResult(
                container: nil,
                didFallbackToInMemory: true,
                failureDescription: underlyingError.localizedDescription
            )
        }
    }
}
