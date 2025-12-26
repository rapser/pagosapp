//
//  PaymentCategory.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import SwiftData

enum PaymentCategory: String, Codable, CaseIterable, Identifiable {
    case servicios = "Servicios"
    case tarjetaCredito = "Tarjeta de Crédito"
    case vivienda = "Vivienda"
    case prestamo = "Préstamo"
    case seguro = "Seguro"
    case educacion = "Educación"
    case impuestos = "Impuestos"
    case suscripcion = "Suscripción"
    case otro = "Otro"

    var id: String { self.rawValue }
}