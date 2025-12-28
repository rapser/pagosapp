//
//  AppError.swift
//  pagosApp
//
//  Unified error handling for the entire app
//  Created by miguel tomairo on 26/12/25.
//

import Foundation

/// Unified app-wide error type that wraps all domain-specific errors
/// This provides a single point of error handling across the app
enum AppError: Error, LocalizedError, UserFacingError {
    // MARK: - Domain Errors
    case authentication(AuthenticationError)
    case payment(PaymentError)
    case network(NetworkError)
    case storage(StorageError)

    // MARK: - Generic Errors
    case unknown(Error)

    // MARK: - Convenience Initializers

    /// Create AppError from any Error
    static func from(_ error: Error) -> AppError {
        if let authError = error as? AuthenticationError {
            return .authentication(authError)
        } else if let paymentError = error as? PaymentError {
            return .payment(paymentError)
        } else if let networkError = error as? NetworkError {
            return .network(networkError)
        } else if let storageError = error as? StorageError {
            return .storage(storageError)
        } else {
            return .unknown(error)
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .authentication(let error):
            return error.errorDescription
        case .payment(let error):
            return error.errorDescription
        case .network(let error):
            return error.errorDescription
        case .storage(let error):
            return error.errorDescription
        case .unknown(let error):
            return "Error inesperado: \(error.localizedDescription)"
        }
    }

    // MARK: - UserFacingError

    var title: String {
        switch self {
        case .authentication(let error):
            return error.title
        case .payment(let error):
            return error.title
        case .network(let error):
            return error.title
        case .storage(let error):
            return error.title
        case .unknown:
            return "Error Inesperado"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authentication(let error):
            return error.recoverySuggestion
        case .payment(let error):
            return error.recoverySuggestion
        case .network(let error):
            return error.recoverySuggestion
        case .storage(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Si el problema persiste, contacta a soporte técnico."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .authentication(let error):
            return error.severity
        case .payment(let error):
            return error.severity
        case .network(let error):
            return error.severity
        case .storage(let error):
            return error.severity
        case .unknown:
            return .error
        }
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError, UserFacingError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No hay conexión a internet."
        case .timeout:
            return "La solicitud ha excedido el tiempo de espera."
        case .serverError(let code):
            return "Error del servidor (código: \(code))."
        case .invalidResponse:
            return "La respuesta del servidor no es válida."
        case .decodingFailed(let error):
            return "Error al procesar los datos: \(error.localizedDescription)"
        }
    }

    var title: String {
        switch self {
        case .noConnection:
            return "Sin Conexión"
        case .timeout:
            return "Tiempo Agotado"
        case .serverError:
            return "Error del Servidor"
        case .invalidResponse:
            return "Respuesta Inválida"
        case .decodingFailed:
            return "Error de Datos"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Verifica tu conexión a internet y vuelve a intentarlo."
        case .timeout:
            return "Verifica tu conexión e intenta nuevamente."
        case .serverError:
            return "El servidor está experimentando problemas. Intenta más tarde."
        case .invalidResponse:
            return "Intenta nuevamente. Si el problema persiste, contacta a soporte."
        case .decodingFailed:
            return "Hubo un problema al procesar la información. Intenta nuevamente."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout:
            return .warning
        case .serverError, .invalidResponse, .decodingFailed:
            return .error
        }
    }
}

// MARK: - Storage Error

enum StorageError: Error, LocalizedError, UserFacingError {
    case saveFailed(Error)
    case loadFailed(Error)
    case deleteFailed(Error)
    case syncFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "No se pudo guardar: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "No se pudo cargar: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "No se pudo eliminar: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Error de sincronización: \(error.localizedDescription)"
        case .notFound:
            return "No se encontró el elemento solicitado."
        }
    }

    var title: String {
        switch self {
        case .saveFailed:
            return "Error al Guardar"
        case .loadFailed:
            return "Error al Cargar"
        case .deleteFailed:
            return "Error al Eliminar"
        case .syncFailed:
            return "Error de Sincronización"
        case .notFound:
            return "No Encontrado"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Verifica que tengas espacio disponible e intenta nuevamente."
        case .loadFailed:
            return "Intenta cerrar y abrir la app nuevamente."
        case .deleteFailed:
            return "Intenta eliminar nuevamente."
        case .syncFailed:
            return "Verifica tu conexión e intenta sincronizar nuevamente."
        case .notFound:
            return "El elemento pudo haber sido eliminado."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .notFound:
            return .warning
        case .saveFailed, .loadFailed, .deleteFailed, .syncFailed:
            return .error
        }
    }
}
