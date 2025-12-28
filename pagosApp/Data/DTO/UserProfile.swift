//
//  UserProfile.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//

import Foundation
import SwiftData

/// SwiftData model for user profile persistence
/// SwiftData manages thread-safety internally through ModelContext.
/// All access must go through ModelContext on @MainActor.
/// For thread-safe operations, use UserProfileEntity instead.
@Model
final class UserProfile {
    @Attribute(.unique) var userId: UUID
    var fullName: String
    var email: String
    var phone: String?
    var dateOfBirth: Date?
    var genderRawValue: String?
    var country: String?
    var city: String?
    var preferredCurrencyRawValue: String
    
    init(userId: UUID, fullName: String, email: String, phone: String? = nil, dateOfBirth: Date? = nil, gender: Gender? = nil, country: String? = nil, city: String? = nil, preferredCurrency: Currency) {
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.genderRawValue = gender?.rawValue
        self.country = country
        self.city = city
        self.preferredCurrencyRawValue = preferredCurrency.rawValue
    }
    
    // Computed properties
    var gender: Gender? {
        get { genderRawValue.flatMap(Gender.init) }
        set { genderRawValue = newValue?.rawValue }
    }
    
    var preferredCurrency: Currency {
        get { Currency(rawValue: preferredCurrencyRawValue) ?? .pen }
        set { preferredCurrencyRawValue = newValue.rawValue }
    }
    
    enum Gender: String, CaseIterable {
        case masculino = "Masculino"
        case femenino = "Femenino"
        case otro = "Otro"
        case prefierNoDecir = "Prefiero no decir"
        
        var displayName: String { rawValue }
    }
}

// DTO for Supabase communication
struct UserProfileDTO: Codable, RemoteTransferable {
    var id: UUID { userId }  // RemoteTransferable requirement
    let userId: UUID
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: Date?
    let gender: String?
    let country: String?
    let city: String?
    let preferredCurrency: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phone
        case dateOfBirth = "date_of_birth"
        case gender
        case country
        case city
        case preferredCurrency = "preferred_currency"
    }
    
    func toModel() -> UserProfile {
        UserProfile(
            userId: userId,
            fullName: fullName,
            email: email,
            phone: phone,
            dateOfBirth: dateOfBirth,
            gender: gender.flatMap(UserProfile.Gender.init),
            country: country,
            city: city,
            preferredCurrency: Currency(rawValue: preferredCurrency) ?? .pen
        )
    }
}
