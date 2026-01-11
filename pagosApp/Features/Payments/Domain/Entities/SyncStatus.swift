//
//  SyncStatus.swift
//  pagosApp
//
//  Domain Entity for Sync Status
//  Clean Architecture - Domain Layer
//

import Foundation

/// Sync status for tracking payment synchronization state
/// Clean Architecture: Domain enums are pure, serialization happens in Data layer
enum SyncStatus: String, Sendable {
    case local      // Solo existe localmente, nunca sincronizado
    case syncing    // En proceso de sincronización
    case synced     // Sincronizado correctamente con Supabase
    case modified   // Existe en Supabase pero fue modificado localmente
    case error      // Falló al sincronizar
}
