//
//  AuthErrorMessageMapper.swift
//  pagosApp
//
//  Single source of truth for AuthError → user-facing messages (internal to Auth module)
//  Auth is an autonomous library; error mapping stays independent within this module.
//

import Foundation

/// Maps domain AuthError to user-facing message strings (Auth module only)
enum AuthErrorMessageMapper {

    /// Auth is an autonomous library; strings stay here. For i18n, Auth can expose a localizer protocol later.
    static func message(for error: AuthError) -> String {
        switch error {
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
            return "Sesión expirada. Vuelve a iniciar sesión"
        case .networkError:
            return "Error de conexión. Verifica tu internet"
        case .unknown(let message):
            return message
        }
    }
}
