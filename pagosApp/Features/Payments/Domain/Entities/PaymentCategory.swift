//
//  PaymentCategory.swift
//  pagosApp
//
//  Domain Entity for Payment Category
//  Clean Architecture - Domain Layer
//

import Foundation

/// Payment category for organizing payments
/// Clean Architecture: Domain enums are pure, serialization happens in Data layer
enum PaymentCategory: String, Sendable, CaseIterable {
    case servicios = "Servicios"
    case tarjetaCredito = "Tarjeta de Crédito"
    case vivienda = "Vivienda"
    case prestamo = "Préstamo"
    case seguro = "Seguro"
    case educacion = "Educación"
    case impuestos = "Impuestos"
    case suscripcion = "Suscripción"
    case otro = "Otro"
}
