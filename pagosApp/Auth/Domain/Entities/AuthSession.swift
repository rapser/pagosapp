//
//  AuthSession.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Session information
struct AuthSession: Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}