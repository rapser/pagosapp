//
//  ModelContextExecutor.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import SwiftData

/// Actor-isolated wrapper for ModelContext
/// This ensures all ModelContext operations happen on MainActor without forcing the entire adapter class
@MainActor
final class ModelContextExecutor {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetch<Entity: PersistentModel>(_ descriptor: FetchDescriptor<Entity>) throws -> [Entity] {
        try modelContext.fetch(descriptor)
    }
    
    func insert<Entity: PersistentModel>(_ entity: Entity) {
        modelContext.insert(entity)
    }
    
    func delete<Entity: PersistentModel>(_ entity: Entity) {
        modelContext.delete(entity)
    }
    
    func save() throws {
        try modelContext.save()
    }
}
