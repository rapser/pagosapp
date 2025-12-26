//
//  for.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific protocol for Payment local storage
protocol PaymentLocalStorage: LocalStorage where Entity == Payment {
    /// Fetch payments by user ID (business logic specific)
    func fetchByUser(_ userId: UUID) async throws -> [Payment]
    
    /// Fetch unpaid payments
    func fetchUnpaid() async throws -> [Payment]
    
    /// Fetch payments pending sync
    func fetchPendingSync() async throws -> [Payment]
}