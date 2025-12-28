//
//  ConfigurationError.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

enum ConfigurationError: Error, LocalizedError {
    case missingKey(String)
    case invalidValue(String)

    var errorDescription: String? {
        switch self {
        case .missingKey(let key):
            return "Falta la clave de configuración: \(key)"
        case .invalidValue(let key):
            return "Valor inválido para la clave: \(key)"
        }
    }
}