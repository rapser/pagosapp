//
//  AuthenticationService.swift
//  pagosApp
//
//  Created by miguel tomairo on 9/09/25.
//  Modern iOS 18+ using async/await
//

import Supabase

protocol AuthenticationService: AnyObject, Sendable {
    var isAuthenticated: Bool { get async }
    var client: SupabaseClient { get }
    
    func observeAuthState() async throws -> AsyncStream<Bool>
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func getCurrentUser() async throws -> String?
    func signUp(email: String, password: String) async throws
    func sendPasswordReset(email: String) async throws
    func setSession(accessToken: String, refreshToken: String) async throws
    func updatePassword(newPassword: String) async throws
}
