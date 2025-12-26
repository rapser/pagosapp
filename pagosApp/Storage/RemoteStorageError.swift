//
//  RemoteStorageError.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Error types for remote storage operations
enum RemoteStorageError: LocalizedError {
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError(String)
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unauthorized:
            return "No autorizado. Por favor inicia sesión nuevamente."
        case .notFound:
            return "Recurso no encontrado"
        case .serverError(let message):
            return "Error del servidor: \(message)"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .timeout:
            return "Tiempo de espera agotado"
        }
    }
}