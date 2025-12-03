//
//  PendingDeletion.swift
//  pagosApp
//
//  Model to track payments pending deletion from server
//

import Foundation
import SwiftData

/// Tracks payments that have been deleted locally but need to be deleted from server
@Model
final class PendingDeletion: @unchecked Sendable {
    @Attribute(.unique) var paymentId: UUID
    var deletedAt: Date
    
    init(paymentId: UUID, deletedAt: Date = Date()) {
        self.paymentId = paymentId
        self.deletedAt = deletedAt
    }
}