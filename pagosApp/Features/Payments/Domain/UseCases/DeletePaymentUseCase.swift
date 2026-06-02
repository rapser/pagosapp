//
//  DeletePaymentUseCase.swift
//  pagosApp
//
//  Use Case for deleting a payment
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for deleting a payment.
/// - Synced payments (`.synced` / `.modified`): deleted from Supabase first, then locally.
///   If Supabase is unreachable the local delete still proceeds (offline-first).
/// - Unsynced payments (`.local`): deleted from SwiftData only — they never reached Supabase.
@MainActor
final class DeletePaymentUseCase {
    private static let logCategory = "DeletePaymentUseCase"

    private let paymentRepository: PaymentRepositoryProtocol
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let log: DomainLogWriter

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        log: DomainLogWriter,
        syncCalendarUseCase: SyncPaymentWithCalendarUseCase? = nil,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.log = log
        self.syncCalendarUseCase = syncCalendarUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the delete payment use case.
    /// - Parameter paymentId: The ID of the payment to delete.
    /// - Returns: Result with success or error.
    func execute(paymentId: UUID) async -> Result<Void, PaymentError> {
        // 1. Fetch local payment to determine sync status and side-effect data
        var paymentToDelete: Payment?
        do {
            paymentToDelete = try await paymentRepository.getLocalPayment(id: paymentId)
        } catch {
            log.warning("⚠️ Could not fetch payment before delete: \(error.localizedDescription)", category: Self.logCategory)
        }

        // 2. Delete from Supabase if the payment was previously synced
        let wasSynced = paymentToDelete?.syncStatus == .synced || paymentToDelete?.syncStatus == .modified
        if wasSynced {
            log.info("🗑 Payment is synced — deleting from Supabase: \(paymentId)", category: Self.logCategory)
            do {
                try await paymentRepository.deletePayment(paymentId: paymentId)
                log.info("✅ Deleted from Supabase: \(paymentId)", category: Self.logCategory)
            } catch {
                // Offline-first: log but do not block the local delete
                log.warning("⚠️ Supabase delete failed (offline?): \(error.localizedDescription) — proceeding with local delete", category: Self.logCategory)
            }
        } else {
            log.info("ℹ️ Payment is local-only — skipping Supabase delete: \(paymentId)", category: Self.logCategory)
        }

        // 3. Delete from SwiftData (always)
        do {
            try await paymentRepository.deleteLocalPayment(id: paymentId)
            log.info("✅ Deleted from local storage: \(paymentId)", category: Self.logCategory)

            // 4. Remove associated calendar event
            if let payment = paymentToDelete, let syncUseCase = syncCalendarUseCase {
                await syncUseCase.removeEvent(for: payment)
            }

            // 5. Cancel scheduled notifications
            if let payment = paymentToDelete, let notificationsUseCase = scheduleNotificationsUseCase {
                notificationsUseCase.cancel(for: payment.id)
            }

            // 6. Publish domain event
            eventBus.publish(PaymentDeletedEvent(paymentId: paymentId))

            return .success(())
        } catch {
            log.error("❌ Failed to delete from local storage: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
