//
//  StorageFactory.swift
//  pagosApp
//
//  Factory Pattern for creating storage configurations
//  Makes it easy to switch between different storage providers
//

import Foundation
import SwiftData
import Supabase

/// Storage provider types
enum StorageProvider {
    case current        // Supabase + SwiftData (current implementation)
    case firebase       // Future: Firebase + SwiftData
    case aws            // Future: AWS + SwiftData
    case local          // Future: No remote, only local (offline mode)
    
    var displayName: String {
        switch self {
        case .current: return "Supabase + SwiftData"
        case .firebase: return "Firebase + SwiftData"
        case .aws: return "AWS DynamoDB + SwiftData"
        case .local: return "Local Only (Offline)"
        }
    }
}

/// Configuration for storage initialization
struct StorageConfiguration {
    let provider: StorageProvider
    let modelContext: ModelContext
    
    // Remote configuration
    var supabaseClient: SupabaseClient?
    // var firebaseFirestore: Firestore?  // Future
    // var awsDynamoDB: DynamoDB?         // Future
    
    /// Default configuration with Supabase
    static func supabase(client: SupabaseClient, modelContext: ModelContext) -> StorageConfiguration {
        StorageConfiguration(
            provider: .current,
            modelContext: modelContext,
            supabaseClient: client
        )
    }
    
    /// Local-only configuration (offline mode)
    static func localOnly(modelContext: ModelContext) -> StorageConfiguration {
        StorageConfiguration(
            provider: .local,
            modelContext: modelContext
        )
    }
}

/// Factory for creating storage adapters and repositories
/// This makes it easy to swap storage providers across the entire app
@MainActor
class StorageFactory {
    
    // MARK: - Singleton
    
    static let shared = StorageFactory()
    private init() {}
    
    private var configuration: StorageConfiguration?
    
    /// Configure the storage provider for the entire app
    /// Call this once during app initialization
    func configure(_ configuration: StorageConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Payment Storage
    
    /// Create PaymentRepository based on configured provider
    func makePaymentRepository() -> PaymentRepositoryProtocol {
        guard let config = configuration else {
            fatalError("❌ StorageFactory not configured. Call configure() first.")
        }
        
        let localStorage = makePaymentLocalStorage(config: config)
        let remoteStorage = makePaymentRemoteStorage(config: config)
        
        return PaymentRepository(remoteStorage: remoteStorage, localStorage: localStorage)
    }
    
    private func makePaymentLocalStorage(config: StorageConfiguration) -> any PaymentLocalStorage {
        // Currently only SwiftData, but can add SQLite, Realm, etc.
        return PaymentSwiftDataStorage(modelContext: config.modelContext)
    }
    
    private func makePaymentRemoteStorage(config: StorageConfiguration) -> any PaymentRemoteStorage {
        switch config.provider {
        case .current:
            guard let client = config.supabaseClient else {
                fatalError("❌ Supabase client not provided")
            }
            return PaymentSupabaseStorage(client: client)
            
        case .firebase:
            // Future implementation
            fatalError("🚧 Firebase not yet implemented")
            // guard let firestore = config.firebaseFirestore else {
            //     fatalError("❌ Firebase firestore not provided")
            // }
            // return PaymentFirebaseStorage(firestore: firestore)
            
        case .aws:
            // Future implementation
            fatalError("🚧 AWS not yet implemented")
            // guard let dynamoDB = config.awsDynamoDB else {
            //     fatalError("❌ AWS DynamoDB not provided")
            // }
            // return PaymentAWSStorage(dynamoDB: dynamoDB)
            
        case .local:
            // Local-only mode with mock remote storage
            return MockPaymentRemoteStorage()
        }
    }
    
    // MARK: - UserProfile Storage
    
    /// Create UserProfileRepository based on configured provider
    func makeUserProfileRepository() -> UserProfileRepositoryProtocol {
        guard let config = configuration else {
            fatalError("❌ StorageFactory not configured. Call configure() first.")
        }
        
        let localStorage = makeUserProfileLocalStorage(config: config)
        let remoteStorage = makeUserProfileRemoteStorage(config: config)
        
        return UserProfileRepository(remoteStorage: remoteStorage, localStorage: localStorage)
    }
    
    private func makeUserProfileLocalStorage(config: StorageConfiguration) -> any UserProfileLocalStorage {
        return UserProfileSwiftDataStorage(modelContext: config.modelContext)
    }
    
    private func makeUserProfileRemoteStorage(config: StorageConfiguration) -> any UserProfileRemoteStorage {
        switch config.provider {
        case .current:
            guard let client = config.supabaseClient else {
                fatalError("❌ Supabase client not provided")
            }
            return UserProfileSupabaseStorage(client: client)
            
        case .firebase:
            fatalError("🚧 Firebase not yet implemented")
            
        case .aws:
            fatalError("🚧 AWS not yet implemented")
            
        case .local:
            return MockUserProfileRemoteStorage()
        }
    }
}

// MARK: - Mock Remote Storage (for offline mode)

/// Mock remote storage for local-only mode
@MainActor
class MockPaymentRemoteStorage: PaymentRemoteStorage {
    func fetchAll(userId _: UUID) async throws -> [PaymentDTO] { [] }
    func fetchById(_: UUID) async throws -> PaymentDTO? { nil }
    func upsert(_: PaymentDTO, userId _: UUID) async throws {}
    func upsertAll(_: [PaymentDTO], userId _: UUID) async throws {}
    func delete(id _: UUID) async throws {}
    func deleteAll(ids _: [UUID]) async throws {}
    func fetchFiltered(userId _: UUID, from _: Date?, to _: Date?) async throws -> [PaymentDTO] { [] }
}

@MainActor
class MockUserProfileRemoteStorage: UserProfileRemoteStorage {
    func fetchAll(userId _: UUID) async throws -> [UserProfileDTO] { [] }
    func fetchById(_: UUID) async throws -> UserProfileDTO? { nil }
    func upsert(_: UserProfileDTO, userId _: UUID) async throws {}
    func upsertAll(_: [UserProfileDTO], userId _: UUID) async throws {}
    func delete(id _: UUID) async throws {}
    func deleteAll(ids _: [UUID]) async throws {}
    func fetchProfile(userId _: UUID) async throws -> UserProfileDTO? { nil }
    func updateProfile(_: UserProfileDTO) async throws {}
}
