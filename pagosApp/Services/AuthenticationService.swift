//
//  AuthenticationService.swift
//  pagosApp
//
//  Created by miguel tomairo on 9/09/25.
//

import Combine

protocol AuthenticationService: AnyObject {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var isAuthenticated: Bool { get }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func getCurrentUser() async throws -> String?
    func signUp(email: String, password: String) async throws
}
