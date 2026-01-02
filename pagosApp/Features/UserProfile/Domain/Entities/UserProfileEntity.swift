//
//  UserProfileEntity.swift
//  pagosApp
//
//  Domain entity for UserProfile (Sendable, thread-safe)
//  Clean Architecture: Domain layer models are Sendable and independent of persistence
//

import Foundation

/// Sendable domain entity for UserProfile
/// This is the thread-safe version used in business logic
struct UserProfileEntity: Sendable {
    let userId: UUID
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: Date?
    let gender: Gender?
    let country: String?
    let city: String?
    let preferredCurrency: Currency
    
    enum Gender: String, Codable, Sendable, CaseIterable {
        case masculino = "Masculino"
        case femenino = "Femenino"
        case otro = "Otro"
        case prefierNoDecir = "Prefiero no decir"

        var displayName: String {
            self.rawValue
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension UserProfileEntity {
    static var mock: UserProfileEntity {
        UserProfileEntity(
            userId: UUID(),
            fullName: "Juan Pérez",
            email: "juan.perez@example.com",
            phone: "+51987654321",
            dateOfBirth: Date(timeIntervalSinceNow: -30 * 365 * 24 * 60 * 60),
            gender: .masculino,
            country: "Perú",
            city: "Lima",
            preferredCurrency: .pen
        )
    }

    static var mockMinimal: UserProfileEntity {
        UserProfileEntity(
            userId: UUID(),
            fullName: "María García",
            email: "maria.garcia@example.com",
            phone: nil,
            dateOfBirth: nil,
            gender: nil,
            country: nil,
            city: nil,
            preferredCurrency: .usd
        )
    }
}
#endif
