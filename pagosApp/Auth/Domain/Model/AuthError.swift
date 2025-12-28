//
//  AuthError.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Authentication errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case userNotFound
    case sessionExpired
    case networkError(Error)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email o contraseña incorrectos"
        case .emailAlreadyExists:
            return "El email ya está registrado"
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres"
        case .invalidEmail:
            return "Email inválido"
        case .userNotFound:
            return "Usuario no encontrado"
        case .sessionExpired:
            return "Sesión expirada. Por favor inicia sesión nuevamente"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unknown(let message):
            return message
        }
    }
}