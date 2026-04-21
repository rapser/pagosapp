//
//  ModelContainerFactory.swift
//  pagosApp
//
//  Factory for creating SwiftData ModelContainer instances.
//  Un solo store (pagos, perfil, recordatorios). No se modifica lógica de pagos.
//

import Foundation
import SwiftData

struct ModelContainerCreationResult: Sendable {
    let container: ModelContainer?
    let didFallbackToInMemory: Bool
    let failureDescription: String?
}

/// Factory responsible for creating and configuring SwiftData ModelContainer
enum ModelContainerFactory {
    private static let logCategory = "ModelContainerFactory"

    /// Creates a configured ModelContainer for the app's data models (pagos, perfil, recordatorios).
    static func create(log: DomainLogWriter) -> ModelContainerCreationResult {
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
            log.error(L10n.Log.Db.modelContainerFailed(error.localizedDescription), category: logCategory)
            return fallbackToInMemoryContainer(log: log, schema: schema, underlyingError: error)
        }
    }

    private static func fallbackToInMemoryContainer(log: DomainLogWriter, schema: Schema, underlyingError: Error) -> ModelContainerCreationResult {
        do {
            let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            return ModelContainerCreationResult(
                container: container,
                didFallbackToInMemory: true,
                failureDescription: underlyingError.localizedDescription
            )
        } catch {
            log.error(L10n.Log.Db.recoveryFailed(error.localizedDescription), category: logCategory)
            return ModelContainerCreationResult(
                container: nil,
                didFallbackToInMemory: true,
                failureDescription: underlyingError.localizedDescription
            )
        }
    }
}
