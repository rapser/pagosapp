//
//  CreatePaymentUseCase.swift
//  pagosApp
//
//  Use Case for creating a new payment
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for creating a new payment with validation and side effects
final class CreatePaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let validator: PaymentValidator
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CreatePaymentUseCase")

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        validator: PaymentValidator = PaymentValidator(),
        syncCalendarUseCase: SyncPaymentWithCalendarUseCase? = nil,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.validator = validator
        self.syncCalendarUseCase = syncCalendarUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the create payment use case
    /// - Parameter payment: The payment entity to create
    /// - Returns: Result with created payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        logger.info("🔨 Creating payment: \(payment.name)")

        // 1. Validate payment
        do {
            try validator.validate(payment)
        } catch let error as PaymentError {
            logger.error("❌ Validation failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Unexpected validation error: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Set initial sync status
        let newPayment = payment
        // We need to ensure syncStatus is .local for new payments
        // Note: Payment is immutable, so repository will handle this

        // 3. Save to repository
        do {
            try await paymentRepository.savePayment(newPayment)
            logger.info("✅ Payment created successfully: \(payment.name)")

            // 4. Sync with calendar (if use case is available)
            if let syncUseCase = syncCalendarUseCase {
                // Request calendar access first
                let granted = await syncUseCase.requestAccess()
                if granted {
                    // Sync payment with calendar
                    let syncResult = await syncUseCase.execute(newPayment)
                    switch syncResult {
                    case .success(let updatedPayment):
                        logger.info("✅ Payment synced with calendar: \(updatedPayment.name)")
                    case .failure(let error):
                        logger.warning("⚠️ Failed to sync payment with calendar: \(error.errorCode)")
                        // Don't fail the whole operation if calendar sync fails
                    }
                } else {
                    logger.info("ℹ️ Calendar access denied, skipping calendar sync")
                }
            }

            // 5. Schedule notifications (if use case is available)
            if let notificationsUseCase = scheduleNotificationsUseCase {
                await MainActor.run {
                    notificationsUseCase.execute(newPayment)
                }
            }

            // Publish domain event (type-safe, reactive)
            await MainActor.run {
                eventBus.publish(PaymentCreatedEvent(paymentId: newPayment.id))
                logger.debug("📢 Published PaymentCreatedEvent")
            }

            return .success(newPayment)
        } catch {
            logger.error("❌ Failed to create payment: \(error.localizedDescription)")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
