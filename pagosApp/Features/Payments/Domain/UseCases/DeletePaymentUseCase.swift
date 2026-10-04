//
//  DeletePaymentUseCase.swift
//  pagosApp
//
//  Use Case for deleting a payment
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for deleting a payment.
/// - Unsynced payments (`.local`): deleted from SwiftData only — they never reached Supabase.
/// - Otherwise: deleted from Supabase first, then locally. If Supabase is unreachable the payment
///   is kept as a hidden tombstone (`.pendingDeletion`) so the next sync deletes it remotely
///   instead of downloading it back.
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

        // 2. Delete from Supabase unless the payment never left this device
        let mayExistRemotely = paymentToDelete.map { $0.syncStatus != .local } ?? false
        var remoteDeleteFailed = false
        if mayExistRemotely {
            log.info("🗑 Deleting from Supabase: \(paymentId)", category: Self.logCategory)
            do {
                try await paymentRepository.deletePayment(paymentId: paymentId)
                log.info("✅ Deleted from Supabase: \(paymentId)", category: Self.logCategory)
            } catch {
                // Offline-first: hide it locally and retry the remote delete on next sync
                remoteDeleteFailed = true
                log.warning("⚠️ Supabase delete failed (offline?): \(error.localizedDescription) — marking for deletion on next sync", category: Self.logCategory)
            }
        } else {
            log.info("ℹ️ Payment is local-only — skipping Supabase delete: \(paymentId)", category: Self.logCategory)
        }

        // 3. Delete from SwiftData (tombstone if Supabase still has it)
        do {
            if remoteDeleteFailed {
                try await paymentRepository.markLocalPaymentPendingDeletion(id: paymentId)
                log.info("🪦 Marked for deletion on next sync: \(paymentId)", category: Self.logCategory)
            } else {
                try await paymentRepository.deleteLocalPayment(id: paymentId)
                log.info("✅ Deleted from local storage: \(paymentId)", category: Self.logCategory)
            }

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
