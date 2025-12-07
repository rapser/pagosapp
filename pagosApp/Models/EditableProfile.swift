//
//  EditableProfile.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import Foundation

/// ViewModel para edición de perfil
/// Mantiene el estado de los campos editables
struct EditableProfile {
    var fullName: String
    var phone: String
    var city: String
    var dateOfBirth: Date?
    var gender: UserProfile.Gender?
    var preferredCurrency: Currency
    
    /// Inicializar desde UserProfile
    init(from profile: UserProfile) {
        self.fullName = profile.fullName
        self.phone = profile.phone ?? ""
        self.city = profile.city ?? ""
        self.dateOfBirth = profile.dateOfBirth
        self.gender = profile.gender
        self.preferredCurrency = profile.preferredCurrency
    }
    
    /// Convertir a ProfileUpdateDTO para enviar a Supabase
    func toUpdateDTO() -> ProfileUpdateDTO {
        ProfileUpdateDTO(
            fullName: fullName,
            email: "", // Email no se actualiza en esta pantalla
            phone: phone.isEmpty ? nil : phone,
            dateOfBirth: dateOfBirth?.ISO8601Format(),
            gender: gender?.rawValue,
            country: nil,
            city: city.isEmpty ? nil : city,
            preferredCurrency: preferredCurrency.rawValue
        )
    }
    
    /// Aplicar cambios a UserProfile
    func applyTo(_ profile: UserProfile) {
        profile.fullName = fullName
        profile.phone = phone.isEmpty ? nil : phone
        profile.city = city.isEmpty ? nil : city
        profile.dateOfBirth = dateOfBirth
        profile.gender = gender
        profile.preferredCurrency = preferredCurrency
    }
}
