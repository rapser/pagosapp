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

    static func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials:
            return L10n.AuthErrorKeys.invalidCredentials
        case .emailAlreadyExists:
            return L10n.AuthErrorKeys.emailExists
        case .weakPassword:
            return L10n.AuthErrorKeys.weakPassword
        case .invalidEmail:
            return L10n.AuthErrorKeys.invalidEmail
        case .userNotFound:
            return L10n.AuthErrorKeys.userNotFound
        case .sessionExpired:
            return L10n.AuthErrorKeys.sessionExpired
        case .networkError:
            return L10n.AuthErrorKeys.network
        case .tooManyLoginAttempts(let until):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return L10n.AuthErrorKeys.tooManyAttempts(formatter.string(from: until))
        case .unknown(let message):
            return L10n.AuthErrorKeys.unknown(message)
        }
    }
}
