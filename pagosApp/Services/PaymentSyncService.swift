//
//  PaymentSyncService.swift
//  pagosApp
//
//  Service for syncing payments with Supabase backend
//

import Foundation
import Supabase
import OSLog

/// Protocol for payment synchronization
/// Now uses Repository Pattern for better separation of concerns
protocol PaymentSyncService {
    func syncPayment(_ payment: Payment, userId: UUID) async throws
    func syncDeletePayment(_ paymentId: UUID) async throws
    func syncDeletePayments(_ paymentIds: [UUID]) async throws
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func syncAllLocalPayments(_ payments: [Payment], userId: UUID) async throws
}

/// Implementation using Repository Pattern
final class DefaultPaymentSyncService: PaymentSyncService {
    private let repository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSync")

    init(repository: PaymentRepositoryProtocol) {
        self.repository = repository
    }

    /// Sync a single payment (upsert: insert or update)
    func syncPayment(_ payment: Payment, userId: UUID) async throws {
        let dto = payment.toDTO(userId: userId)

        do {
            logger.info("Syncing payment: \(payment.name) (ID: \(payment.id))")
            
            try await repository.upsertPayment(userId: userId, payment: dto)
            
            logger.info("✅ Payment synced successfully: \(payment.name)")
        } catch {
            logger.error("❌ Failed to sync payment: \(error.localizedDescription)")
            throw PaymentSyncError.syncFailed(error)
        }
    }

    /// Sync deletion of a payment
    func syncDeletePayment(_ paymentId: UUID) async throws {
        do {
            logger.info("Deleting payment from server: \(paymentId)")
            
            try await repository.deletePayment(paymentId: paymentId)
            
            logger.info("✅ Payment deleted from server: \(paymentId)")
        } catch {
            logger.error("❌ Failed to delete payment from server: \(error.localizedDescription)")
            throw PaymentSyncError.deleteFailed(error)
        }
    }
    
    /// Sync deletion of multiple payments
    func syncDeletePayments(_ paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else {
            logger.info("No payments to delete")
            return
        }
        
        do {
            logger.info("Deleting \(paymentIds.count) payments from server")
            
            try await repository.deletePayments(paymentIds: paymentIds)
            
            logger.info("✅ Deleted \(paymentIds.count) payments from server")
        } catch {
            logger.error("❌ Failed to delete payments from server: \(error.localizedDescription)")
            throw PaymentSyncError.deleteFailed(error)
        }
    }

    /// Fetch all payments from server
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        do {
            logger.info("Fetching all payments from server for user: \(userId)")
            
            let response = try await repository.fetchAllPayments(userId: userId)
            
            logger.info("✅ Fetched \(response.count) payments from server")
            return response
        } catch {
            logger.error("❌ Failed to fetch payments: \(error.localizedDescription)")
            throw PaymentSyncError.fetchFailed(error)
        }
    }

    /// Sync all local payments to server (bulk upsert)
    func syncAllLocalPayments(_ payments: [Payment], userId: UUID) async throws {
        let dtos = payments.map { $0.toDTO(userId: userId) }

        guard !dtos.isEmpty else {
            logger.info("No payments to sync")
            return
        }

        do {
            logger.info("Syncing \(dtos.count) payments to server")
            
            try await repository.upsertPayments(userId: userId, payments: dtos)
            
            logger.info("✅ Synced \(dtos.count) payments successfully")
        } catch {
            logger.error("❌ Failed to sync payments: \(error.localizedDescription)")
            throw PaymentSyncError.syncFailed(error)
        }
    }
}

// MARK: - Sync Errors

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
