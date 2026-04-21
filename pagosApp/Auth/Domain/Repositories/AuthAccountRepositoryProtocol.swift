//
//  AuthAccountRepositoryProtocol.swift
//  pagosApp
//
//  Account lifecycle (ISP split).
//

import Foundation

@MainActor
protocol AuthAccountRepositoryProtocol: AnyObject, Sendable {
    func deleteAccount() async -> Result<Void, AuthError>
}
