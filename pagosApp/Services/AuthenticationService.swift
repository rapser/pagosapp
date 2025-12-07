//
//  AuthenticationService.swift
//  pagosApp
//
//  Created by miguel tomairo on 9/09/25.
//

import Combine
import Supabase

protocol AuthenticationService: AnyObject {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var isAuthenticated: Bool { get }
    var client: SupabaseClient { get }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func getCurrentUser() async throws -> String?
    func signUp(email: String, password: String) async throws
    func sendPasswordReset(email: String) async throws
    func setSession(accessToken: String, refreshToken: String) async throws
    func updatePassword(newPassword: String) async throws
}
