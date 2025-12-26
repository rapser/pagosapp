//
//  PaymentSupabaseStorage.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import Supabase

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
