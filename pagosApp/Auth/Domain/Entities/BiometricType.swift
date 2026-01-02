//
//  BiometricType.swift
//  pagosApp
//
//  Biometric authentication types
//  Clean Architecture - Domain Layer
//

import Foundation

/// Types of biometric authentication supported
enum BiometricType: String, Sendable {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"
    case none = "None"

    /// User-friendly description
    var description: String {
        rawValue
    }
}
