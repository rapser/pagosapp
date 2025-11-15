//
//  PaymentError.swift
//  pagosApp
//
//  Created by Claude Code
//

import Foundation

enum PaymentError: Error, LocalizedError, UserFacingError {
    case invalidAmount
    case invalidDate
    case saveFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case notificationScheduleFailed(Error)
    case calendarSyncFailed(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "El monto debe ser mayor a cero."
        case .invalidDate:
            return "La fecha seleccionada no es válida."
        case .saveFailed(let error):
            return "No se pudo guardar el pago: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "No se pudo eliminar el pago: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "No se pudo actualizar el pago: \(error.localizedDescription)"
        case .notificationScheduleFailed(let error):
            return "No se pudo programar la notificación: \(error.localizedDescription)"
        case .calendarSyncFailed(let error):
            return "No se pudo sincronizar con el calendario: \(error.localizedDescription)"
        }
    }

    // MARK: - UserFacingError

    var title: String {
        switch self {
        case .invalidAmount:
            return "Monto Inválido"
        case .invalidDate:
            return "Fecha Inválida"
        case .saveFailed:
            return "Error al Guardar"
        case .deleteFailed:
            return "Error al Eliminar"
        case .updateFailed:
            return "Error al Actualizar"
        case .notificationScheduleFailed:
            return "Error de Notificación"
        case .calendarSyncFailed:
            return "Error de Calendario"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidAmount:
            return "Ingresa un monto válido mayor a $0"
        case .invalidDate:
            return "Selecciona una fecha válida para el pago"
        case .saveFailed:
            return "Verifica que todos los campos estén completos e intenta nuevamente"
        case .deleteFailed:
            return "Intenta eliminar el pago nuevamente"
        case .updateFailed:
            return "Verifica los cambios e intenta guardar nuevamente"
        case .notificationScheduleFailed:
            return "Verifica que las notificaciones estén habilitadas en Ajustes"
        case .calendarSyncFailed:
            return "Verifica que el acceso al calendario esté habilitado en Ajustes"
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .invalidAmount, .invalidDate:
            return .warning
        case .saveFailed, .deleteFailed, .updateFailed:
            return .error
        case .notificationScheduleFailed, .calendarSyncFailed:
            return .warning
        }
    }
}
