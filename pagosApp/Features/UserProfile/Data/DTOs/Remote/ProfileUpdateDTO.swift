//
//  ProfileUpdateDTO.swift
//  pagosApp
//
//  Remote DTO for updating user profile in Supabase
//  Clean Architecture: Data layer - Remote DTO
//

import Foundation

/// DTO for profile update requests to Supabase
struct ProfileUpdateDTO: Encodable {
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: String?
    let gender: String?
    let country: String?
    let city: String?
    let preferredCurrency: String

    enum CodingKeys: String, CodingKey {
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
