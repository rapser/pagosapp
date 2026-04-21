//
//  AuthRepositoryProtocol.swift
//  pagosApp
//
//  Full auth repository: composition of session, credential, and account capabilities.
//

import Foundation

/// Full authentication repository for callers that need every capability (e.g. DI root).
@MainActor
protocol AuthRepositoryProtocol: AuthSessionRepositoryProtocol, AuthCredentialRepositoryProtocol, AuthAccountRepositoryProtocol {}
