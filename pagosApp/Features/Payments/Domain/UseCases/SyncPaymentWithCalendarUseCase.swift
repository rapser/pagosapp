//
//  SyncPaymentWithCalendarUseCase.swift
//  pagosApp
//
//  Use Case for syncing payment with device calendar
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for syncing a payment with the device calendar
final class SyncPaymentWithCalendarUseCase {
    private let calendarEventDataSource: CalendarEventDataSource
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SyncPaymentWithCalendarUseCase")

    init(
        calendarEventDataSource: CalendarEventDataSource,
        paymentRepository: PaymentRepositoryProtocol
    ) {
        self.calendarEventDataSource = calendarEventDataSource
        self.paymentRepository = paymentRepository
    }

    /// Request calendar access (async/await - preferred)
    func requestAccess() async -> Bool {
        await calendarEventDataSource.requestAccess()
    }
    
    /// Request calendar access (callback-based - for compatibility)
    func requestAccess(completion: @escaping (Bool) -> Void) {
        Task {
            let granted = await requestAccess()
            await MainActor.run {
                completion(granted)
            }
        }
    }

    /// Sync a payment with calendar (create or update event)
    /// - Parameter payment: The payment to sync
    /// - Returns: Result with updated payment (with eventIdentifier) or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        logger.info("📅 Syncing payment with calendar: \(payment.name)")

        // Check if payment is part of a group
        if let groupId = payment.groupId {
            return await syncGroupedPayment(payment: payment, groupId: groupId)
        } else {
            return await syncSinglePayment(payment: payment)
        }
    }

    /// Sync a single payment (not grouped)
    private func syncSinglePayment(payment: Payment) async -> Result<Payment, PaymentError> {
        let title = "Pago: \(payment.name)"

        // If payment already has an event, update it
        if let eventId = payment.eventIdentifier {
            calendarEventDataSource.updateEvent(
                eventIdentifier: eventId,
                title: title,
                dueDate: payment.dueDate,
                isPaid: payment.isPaid
            )
            logger.info("✅ Calendar event updated: \(eventId)")
            return .success(payment)
        }

        // Otherwise, create a new event
        return await createCalendarEvent(for: payment, title: title)
    }

    /// Sync a grouped payment (PEN + USD) - only create/update one event for the group
    private func syncGroupedPayment(payment: Payment, groupId: UUID) async -> Result<Payment, PaymentError> {
        logger.info("🔗 Syncing grouped payment: \(groupId)")

        do {
            // Get all payments in the group
            let allPayments = try await paymentRepository.getAllLocalPayments()
            let groupPayments = allPayments.filter { $0.groupId == groupId }

            // Find the payment that already has an eventIdentifier (if any)
            let paymentWithEvent = groupPayments.first { $0.eventIdentifier != nil }

            let title = "Pago: \(payment.name)"

            // If one payment in the group already has an event, use that eventIdentifier for all
            if let existingEventId = paymentWithEvent?.eventIdentifier {
                // Update the existing event
                calendarEventDataSource.updateEvent(
                    eventIdentifier: existingEventId,
                    title: title,
                    dueDate: payment.dueDate,
                    isPaid: payment.isPaid
                )

                // Update all payments in the group to share the same eventIdentifier
                var updatedPayment = payment
                if payment.eventIdentifier != existingEventId {
                    updatedPayment = Payment(
                        id: payment.id,
                        name: payment.name,
                        amount: payment.amount,
                        currency: payment.currency,
                        dueDate: payment.dueDate,
                        isPaid: payment.isPaid,
                        category: payment.category,
                        eventIdentifier: existingEventId,
                        syncStatus: payment.syncStatus,
                        lastSyncedAt: payment.lastSyncedAt,
                        groupId: payment.groupId
                    )

                    // Update sibling payments to share the same eventIdentifier
                    for siblingPayment in groupPayments where siblingPayment.id != payment.id {
                        let updatedSibling = Payment(
                            id: siblingPayment.id,
                            name: siblingPayment.name,
                            amount: siblingPayment.amount,
                            currency: siblingPayment.currency,
                            dueDate: siblingPayment.dueDate,
                            isPaid: siblingPayment.isPaid,
                            category: siblingPayment.category,
                            eventIdentifier: existingEventId,
                            syncStatus: siblingPayment.syncStatus,
                            lastSyncedAt: siblingPayment.lastSyncedAt,
                            groupId: siblingPayment.groupId
                        )
                        try await paymentRepository.savePayment(updatedSibling)
                    }
                }

                logger.info("✅ Grouped payment calendar event updated: \(existingEventId)")
                return .success(updatedPayment)
            } else {
                // No event exists yet, create one and share it with all payments in the group
                return await createCalendarEventForGroup(payment: payment, groupPayments: groupPayments, title: title)
            }
        } catch {
            logger.error("❌ Failed to sync grouped payment: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Create a calendar event for a single payment
    private func createCalendarEvent(for payment: Payment, title: String) async -> Result<Payment, PaymentError> {
        let eventIdentifier = await calendarEventDataSource.addEvent(title: title, dueDate: payment.dueDate)

        guard let eventIdentifier = eventIdentifier else {
            logger.error("❌ Failed to create calendar event")
            return .failure(.calendarSyncFailed("No se pudo crear el evento en el calendario"))
        }

        // Update payment with eventIdentifier
        let updatedPayment = Payment(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: eventIdentifier,
            syncStatus: payment.syncStatus,
            lastSyncedAt: payment.lastSyncedAt,
            groupId: payment.groupId
        )

        do {
            try await paymentRepository.savePayment(updatedPayment)
            logger.info("✅ Calendar event created and payment updated: \(eventIdentifier)")
            return .success(updatedPayment)
        } catch {
            logger.error("❌ Failed to save payment with eventIdentifier: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    /// Create a calendar event for a grouped payment and share it with all payments in the group
    private func createCalendarEventForGroup(
        payment: Payment,
        groupPayments: [Payment],
        title: String
    ) async -> Result<Payment, PaymentError> {
        let eventIdentifier = await calendarEventDataSource.addEvent(title: title, dueDate: payment.dueDate)

        guard let eventIdentifier = eventIdentifier else {
            logger.error("❌ Failed to create calendar event for group")
            return .failure(.calendarSyncFailed("No se pudo crear el evento en el calendario"))
        }

        // Update all payments in the group to share the same eventIdentifier
        let updatedPayment = Payment(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: eventIdentifier,
            syncStatus: payment.syncStatus,
            lastSyncedAt: payment.lastSyncedAt,
            groupId: payment.groupId
        )

        do {
            try await paymentRepository.savePayment(updatedPayment)

            // Update sibling payments to share the same eventIdentifier
            for siblingPayment in groupPayments where siblingPayment.id != payment.id {
                let updatedSibling = Payment(
                    id: siblingPayment.id,
                    name: siblingPayment.name,
                    amount: siblingPayment.amount,
                    currency: siblingPayment.currency,
                    dueDate: siblingPayment.dueDate,
                    isPaid: siblingPayment.isPaid,
                    category: siblingPayment.category,
                    eventIdentifier: eventIdentifier,
                    syncStatus: siblingPayment.syncStatus,
                    lastSyncedAt: siblingPayment.lastSyncedAt,
                    groupId: siblingPayment.groupId
                )
                try await paymentRepository.savePayment(updatedSibling)
            }

            logger.info("✅ Calendar event created for group and all payments updated: \(eventIdentifier)")
            return .success(updatedPayment)
        } catch {
            logger.error("❌ Failed to save grouped payments with eventIdentifier: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    /// Remove calendar event for a payment
    /// - Parameter payment: The payment whose event should be removed
    func removeEvent(for payment: Payment) async {
        guard let eventId = payment.eventIdentifier else { return }

        // For grouped payments, check if other payments in the group still need the event
        if let groupId = payment.groupId {
            do {
                let allPayments = try await paymentRepository.getAllLocalPayments()
                let groupPayments = allPayments.filter { $0.groupId == groupId && $0.id != payment.id }

                // Only remove event if no other payment in the group needs it
                if groupPayments.isEmpty || groupPayments.allSatisfy({ $0.eventIdentifier != eventId }) {
                    calendarEventDataSource.removeEvent(eventIdentifier: eventId)
                    logger.info("✅ Calendar event removed: \(eventId)")
                } else {
                    logger.info("ℹ️ Keeping calendar event as other payments in group still need it")
                }
            } catch {
                logger.error("❌ Failed to check grouped payments: \(error.localizedDescription)")
                // Remove event anyway if we can't check
                calendarEventDataSource.removeEvent(eventIdentifier: eventId)
            }
        } else {
            calendarEventDataSource.removeEvent(eventIdentifier: eventId)
            logger.info("✅ Calendar event removed: \(eventId)")
        }
    }
}
