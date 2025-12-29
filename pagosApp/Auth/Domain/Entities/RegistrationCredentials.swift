//
//  RegistrationCredentials.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Credentials for registration
struct RegistrationCredentials {
    let email: String
    let password: String
    let metadata: [String: String]?
    
    init(email: String, password: String, metadata: [String: String]? = nil) {
        self.email = email
        self.password = password
        self.metadata = metadata
    }
}