//
//  UserProfileDTO.swift
//  pagosApp
//
//  Remote DTO for Supabase communication
//  Clean Architecture: Data layer - Remote DTO
//

import Foundation

/// DTO for Supabase communication
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
}
