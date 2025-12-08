//
//  SupabaseStorageAdapter.swift
//  pagosApp
//
//  Adapter for Supabase remote storage (Adapter Pattern)
//  Can be replaced with FirebaseStorageAdapter, AWSStorageAdapter, etc.
//

import Foundation
import Supabase
import OSLog

/// Adapter to use Supabase as RemoteStorage implementation
/// This can be swapped with Firebase, AWS, REST API implementations
class SupabaseStorageAdapter<DTO: RemoteTransferable>: RemoteStorage {
    typealias Identifier = DTO.Identifier
    
    internal let client: SupabaseClient
    internal let tableName: String
    private let logger: Logger
    
    init(client: SupabaseClient, tableName: String) {
        self.client = client
        self.tableName = tableName
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SupabaseStorage-\(tableName)")
    }
    
    func fetchAll(userId: UUID) async throws -> [DTO] {
        do {
            let response: [DTO] = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            logger.debug("✅ Fetched \(response.count) items from Supabase (\(self.tableName))")
            return response
        } catch let decodingError as DecodingError {
            logger.error("❌ Decoding error fetching from Supabase: \(decodingError.localizedDescription)")
            // Log more details about the decoding error
            switch decodingError {
            case .dataCorrupted(let context):
                logger.error("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                logger.error("Key not found: \(key.stringValue) - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.error("Type mismatch: expected \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.error("Value not found: expected \(type) - \(context.debugDescription)")
            @unknown default:
                logger.error("Unknown decoding error")
            }
            throw RemoteStorageError.networkError(decodingError)
        } catch {
            logger.error("❌ Failed to fetch from Supabase: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
    
    func fetchById(_ id: Identifier) async throws -> DTO? {
        do {
            let idString = "\(id)"
            let query = client
                .from(tableName)
                .select()
                .eq("id", value: idString)
                .limit(1)
            
            let response: [DTO] = try await query.execute().value
            
            logger.debug("✅ Fetched item from Supabase: \(idString)")
            return response.first
        } catch {
            logger.error("❌ Failed to fetch by ID: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
    
    func upsert(_ dto: DTO, userId: UUID) async throws {
        do {
            try await client
                .from(tableName)
                .upsert(dto)
                .execute()
            
            logger.debug("✅ Upserted item to Supabase (\(self.tableName))")
        } catch {
            logger.error("❌ Failed to upsert: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
    
    func upsertAll(_ dtos: [DTO], userId: UUID) async throws {
        do {
            try await client
                .from(tableName)
                .upsert(dtos)
                .execute()
            
            logger.debug("✅ Upserted \(dtos.count) items to Supabase (\(self.tableName))")
        } catch {
            logger.error("❌ Failed to upsert multiple: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
    
    func delete(id: Identifier) async throws {
        do {
            let idString = "\(id)"
            try await client
                .from(tableName)
                .delete()
                .eq("id", value: idString)
                .execute()
            
            logger.debug("✅ Deleted item from Supabase: \(idString)")
        } catch {
            logger.error("❌ Failed to delete: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
    
    func deleteAll(ids: [Identifier]) async throws {
        do {
            let idsString: [String] = ids.map { "\($0)" }
            try await client
                .from(tableName)
                .delete()
                .in("id", values: idsString)
                .execute()
            
            logger.debug("✅ Deleted \(ids.count) items from Supabase")
        } catch {
            logger.error("❌ Failed to delete multiple: \(error.localizedDescription)")
            throw RemoteStorageError.networkError(error)
        }
    }
}

/// Specific Supabase adapter for Payment
final class PaymentSupabaseStorage: SupabaseStorageAdapter<PaymentDTO>, PaymentRemoteStorage {
    
    init(client: SupabaseClient) {
        super.init(client: client, tableName: "payments")
    }
    
    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO] {
        var query = client
            .from("payments")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let from = from {
            query = query.gte("due_date", value: from)
        }
        
        if let to = to {
            query = query.lte("due_date", value: to)
        }
        
        let response: [PaymentDTO] = try await query.execute().value
        return response
    }
}

/// Specific Supabase adapter for UserProfile
final class UserProfileSupabaseStorage: SupabaseStorageAdapter<UserProfileDTO>, UserProfileRemoteStorage {
    
    init(client: SupabaseClient) {
        super.init(client: client, tableName: "user_profiles")
    }
    
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO? {
        let profiles: [UserProfileDTO] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return profiles.first
    }
    
    func updateProfile(_ dto: UserProfileDTO) async throws {
        try await client
            .from("user_profiles")
            .update(dto)
            .eq("user_id", value: dto.userId.uuidString)
            .execute()
    }
}

// MARK: - Future implementations (examples)

/*
/// Example: Firebase adapter (future implementation)
final class PaymentFirebaseStorage: PaymentRemoteStorage {
    typealias DTO = PaymentDTO
    typealias Identifier = UUID
    
    private let firestore: Firestore
    
    init(firestore: Firestore) {
        self.firestore = firestore
    }
    
    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        // Firebase specific implementation
        let snapshot = try await firestore
            .collection("payments")
            .whereField("userId", isEqualTo: userId.uuidString)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: PaymentDTO.self) }
    }
    
    // ... other methods
}

/// Example: AWS DynamoDB adapter (future implementation)
final class PaymentAWSStorage: PaymentRemoteStorage {
    typealias DTO = PaymentDTO
    typealias Identifier = UUID
    
    private let dynamoDB: DynamoDB
    
    init(dynamoDB: DynamoDB) {
        self.dynamoDB = dynamoDB
    }
    
    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        // AWS DynamoDB specific implementation
        let request = QueryInput(
            tableName: "payments",
            keyConditionExpression: "userId = :userId",
            expressionAttributeValues: [":userId": .s(userId.uuidString)]
        )
        let response = try await dynamoDB.query(input: request)
        return response.items?.compactMap { /* decode */ } ?? []
    }
    
    // ... other methods
}

/// Example: REST API adapter (future implementation)
final class PaymentRESTStorage: PaymentRemoteStorage {
    typealias DTO = PaymentDTO
    typealias Identifier = UUID
    
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        // REST API specific implementation
        let url = baseURL.appendingPathComponent("payments")
            .appending(queryItems: [URLQueryItem(name: "userId", value: userId.uuidString)])
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([PaymentDTO].self, from: data)
    }
    
    // ... other methods
}
*/
