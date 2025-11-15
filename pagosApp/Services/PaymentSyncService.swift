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
protocol PaymentSyncService {
    func syncPayment(_ payment: Payment) async throws
    func syncDeletePayment(_ paymentId: UUID) async throws
    func fetchAllPayments() async throws -> [PaymentDTO]
    func syncAllLocalPayments(_ payments: [Payment]) async throws
}

/// Supabase implementation of payment sync service
class SupabasePaymentSyncService: PaymentSyncService {
    private let client: SupabaseClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSync")

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Get current user ID
    private func getCurrentUserId() throws -> UUID {
        guard let userId = client.auth.currentUser?.id else {
            throw PaymentSyncError.notAuthenticated
        }
        return userId
    }

    /// Sync a single payment (upsert: insert or update)
    func syncPayment(_ payment: Payment) async throws {
        let userId = try getCurrentUserId()
        let dto = payment.toDTO(userId: userId)

        do {
            logger.info("Syncing payment: \(payment.name) (ID: \(payment.id))")

            // Upsert payment (insert or update)
            try await client
                .from("payments")
                .upsert(dto)
                .execute()

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

            try await client
                .from("payments")
                .delete()
                .eq("id", value: paymentId.uuidString)
                .execute()

            logger.info("✅ Payment deleted from server: \(paymentId)")
        } catch {
            logger.error("❌ Failed to delete payment from server: \(error.localizedDescription)")
            throw PaymentSyncError.deleteFailed(error)
        }
    }

    /// Fetch all payments from server
    func fetchAllPayments() async throws -> [PaymentDTO] {
        let userId = try getCurrentUserId()

        do {
            logger.info("Fetching all payments from server for user: \(userId)")

            let response: [PaymentDTO] = try await client
                .from("payments")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            logger.info("✅ Fetched \(response.count) payments from server")
            return response
        } catch {
            logger.error("❌ Failed to fetch payments: \(error.localizedDescription)")
            throw PaymentSyncError.fetchFailed(error)
        }
    }

    /// Sync all local payments to server (bulk upsert)
    func syncAllLocalPayments(_ payments: [Payment]) async throws {
        let userId = try getCurrentUserId()
        let dtos = payments.map { $0.toDTO(userId: userId) }

        guard !dtos.isEmpty else {
            logger.info("No payments to sync")
            return
        }

        do {
            logger.info("Syncing \(dtos.count) payments to server")

            try await client
                .from("payments")
                .upsert(dtos)
                .execute()

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
