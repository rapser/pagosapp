//
//  for 4.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific protocol for Payment remote storage
protocol PaymentRemoteStorage: RemoteStorage where DTO == PaymentDTO, Identifier == UUID {
    /// Fetch payments with filters (optional business logic)
    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO]
}