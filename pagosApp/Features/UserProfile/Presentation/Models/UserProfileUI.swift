//
//  UserProfileUI.swift
//  pagosApp
//
//  Presentation model for UserProfile
//  Clean Architecture - Presentation Layer Model
//

import Foundation

/// Presentation model for UserProfile
/// Used in ViewModels and Views (Identifiable for SwiftUI)
struct UserProfileUI: Identifiable, Sendable {
    var id: UUID { userId }  // Identifiable requirement for SwiftUI
    let userId: UUID
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: Date?
    let gender: UserProfile.Gender?
    let country: String?
    let city: String?
    let preferredCurrency: Currency

    // MARK: - Mock Data for Previews

    static let mock = UserProfileUI(
        userId: UUID(),
        fullName: "Juan Pérez",
        email: "juan.perez@example.com",
        phone: "+51 987654321",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
        gender: .masculino,
        country: "Perú",
        city: "Lima",
        preferredCurrency: .pen
    )

    static let mockMinimal = UserProfileUI(
        userId: UUID(),
        fullName: "María García",
        email: "maria.garcia@example.com",
        phone: nil,
        dateOfBirth: nil,
        gender: nil,
        country: nil,
        city: nil,
        preferredCurrency: .pen
    )
}
