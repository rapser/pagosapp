//
//  SupabaseSessionDTO.swift
//  pagosApp
//
//  Supabase session data transfer object
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// DTO representing session data from Supabase
struct SupabaseSessionDTO {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let user: SupabaseUserDTO

    /// Initialize from Supabase Session
    init(from session: Session) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.expiresAt = Int(session.expiresAt)
        self.user = SupabaseUserDTO(from: session.user)
    }
}
