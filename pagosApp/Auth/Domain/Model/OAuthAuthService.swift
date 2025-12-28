//
//  for 2.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific protocol for OAuth authentication (optional)
protocol OAuthAuthService: AuthService {
    /// Sign in with Google
    func signInWithGoogle() async throws -> AuthSession
    
    /// Sign in with Apple
    func signInWithApple() async throws -> AuthSession
    
    /// Sign in with Facebook
    func signInWithFacebook() async throws -> AuthSession
}