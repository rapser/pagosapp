//
//  UserProfileUIMapping.swift
//  pagosApp
//
//  Protocol for mapping between UserProfile (Domain) and UserProfileUI (Presentation)
//  Clean Architecture - Presentation Layer Mapper Protocol
//

import Foundation

/// Protocol for mapping between UserProfile (Domain) and UserProfileUI (Presentation)
/// SOLID: Dependency Inversion Principle - depend on abstractions, not concretions
protocol UserProfileUIMapping: Sendable {
    /// Convert from Domain to Presentation
    func toUI(_ domain: UserProfile) -> UserProfileUI

    /// Convert from Presentation to Domain
    func toDomain(_ ui: UserProfileUI) -> UserProfile
}
