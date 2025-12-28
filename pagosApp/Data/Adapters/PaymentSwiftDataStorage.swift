//
//  PaymentSwiftDataStorage.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific SwiftData adapter for Payment
final class PaymentSwiftDataStorage: SwiftDataStorageAdapter<Payment>, PaymentLocalStorage {
    
    func fetchByUser(_ userId: UUID) async throws -> [Payment] {
        // Local storage doesn't have userId field in Payment model
        // Return all payments as local storage only contains current user's data
        return try await fetchAll()
    }
    
    func fetchUnpaid() async throws -> [Payment] {
        let allPayments = try await fetchAll()
        return allPayments.filter { !$0.isPaid }
    }
    
    func fetchPendingSync() async throws -> [Payment] {
        let allPayments = try await fetchAll()
        // Payments that need sync are those with status .local or .modified
        return allPayments.filter { $0.syncStatus == .local || $0.syncStatus == .modified }
    }
}
