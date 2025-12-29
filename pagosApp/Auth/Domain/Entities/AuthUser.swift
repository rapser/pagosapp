//
//  AuthUser.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Authentication result with user data
struct AuthUser: Sendable {
    let id: UUID
    let email: String
    let emailConfirmed: Bool
    let createdAt: Date
    let metadata: [String: String]?
    
    init(id: UUID, email: String, emailConfirmed: Bool = false, createdAt: Date = Date(), metadata: [String: String]? = nil) {
        self.id = id
        self.email = email
        self.emailConfirmed = emailConfirmed
        self.createdAt = createdAt
        self.metadata = metadata
    }
}