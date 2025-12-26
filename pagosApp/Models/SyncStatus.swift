//
//  SyncStatus.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import SwiftData

enum SyncStatus: String, Codable {
    case local      // Solo existe localmente, nunca sincronizado
    case syncing    // En proceso de sincronización
    case synced     // Sincronizado correctamente con Supabase
    case modified   // Existe en Supabase pero fue modificado localmente
    case error      // Falló al sincronizar
}