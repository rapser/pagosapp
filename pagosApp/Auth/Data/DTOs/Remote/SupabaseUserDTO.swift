//
//  SupabaseUserDTO.swift
//  pagosApp
//
//  Supabase user data transfer object
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// DTO representing user data from Supabase
struct SupabaseUserDTO {
    let id: UUID
    let email: String
    let emailConfirmedAt: Date?
    let createdAt: Date
    let userMetadata: [String: AnyJSON]

    /// Initialize from Supabase User
    init(from user: User) {
        self.id = user.id
        self.email = user.email ?? ""
        self.emailConfirmedAt = user.emailConfirmedAt
        self.createdAt = user.createdAt
        self.userMetadata = user.userMetadata
    }
}
