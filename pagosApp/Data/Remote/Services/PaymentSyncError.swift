//
//  PaymentSyncError.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

enum PaymentSyncError: Error, LocalizedError, UserFacingError {
    case notAuthenticated
    case syncFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No has iniciado sesión. Por favor, inicia sesión para sincronizar."
        case .syncFailed(let error):
            return "Error al sincronizar: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Error al obtener pagos: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Error al eliminar pago: \(error.localizedDescription)"
        case .networkError:
            return "Error de red. Verifica tu conexión a internet."
        }
    }

    var title: String {
        switch self {
        case .notAuthenticated:
            return "No Autenticado"
        case .syncFailed:
            return "Error de Sincronización"
        case .fetchFailed:
            return "Error al Descargar"
        case .deleteFailed:
            return "Error al Eliminar"
        case .networkError:
            return "Sin Conexión"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Inicia sesión para poder sincronizar tus pagos"
        case .syncFailed, .fetchFailed, .deleteFailed:
            return "Verifica tu conexión a internet e intenta nuevamente"
        case .networkError:
            return "Conecta a internet y vuelve a intentar"
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .notAuthenticated:
            return .warning
        case .syncFailed, .fetchFailed, .deleteFailed:
            return .error
        case .networkError:
            return .warning
        }
    }
}
