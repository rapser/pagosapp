//
//  PaymentErrorMessageMapper.swift
//  pagosApp
//
//  Single source of truth for PaymentError → user-facing messages
//  Clean Architecture: Presentation layer (domain stays free of UI text)
//

import Foundation

/// Maps domain PaymentError to user-facing message strings
enum PaymentErrorMessageMapper {

    static func message(for error: PaymentError) -> String {
        switch error {
        case .invalidName:
            return "El nombre del pago es requerido"
        case .invalidAmount:
            return "El monto debe ser mayor a cero"
        case .invalidDate:
            return "La fecha seleccionada no es válida"
        case .saveFailed(let details):
            return "No se pudo guardar el pago: \(details)"
        case .deleteFailed(let details):
            return "No se pudo eliminar el pago: \(details)"
        case .updateFailed(let details):
            return "No se pudo actualizar el pago: \(details)"
        case .notificationScheduleFailed(let details):
            return "No se pudieron programar las notificaciones: \(details)"
        case .calendarSyncFailed(let details):
            return "No se pudo sincronizar con el calendario: \(details)"
        case .notFound:
            return "No se encontró el pago"
        case .unknown(let details):
            return "Error: \(details)"
        }
    }
}
