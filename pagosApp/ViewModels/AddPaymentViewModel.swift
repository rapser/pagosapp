//
//  AddPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for AddPaymentView following MVVM architecture
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftUI
import SwiftData
import Observation
import OSLog

@MainActor
@Observable
final class AddPaymentViewModel {
    // MARK: - Observable Properties

    var name: String = ""
    var amount: String = ""
    var currency: Currency = .pen
    var dueDate: Date = Date()
    var category: PaymentCategory = .servicios
    var isLoading = false

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let modelContext: ModelContext
    private let paymentOperations: PaymentOperationsService
    private let errorHandler: ErrorHandler
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "AddPaymentViewModel")

    // MARK: - Validation

    var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    var amountValue: Double? {
        Double(amount)
    }

    // MARK: - Initialization (DIP: inject dependencies)

    init(modelContext: ModelContext, paymentOperations: PaymentOperationsService, errorHandler: ErrorHandler) {
        self.modelContext = modelContext
        self.paymentOperations = paymentOperations
        self.errorHandler = errorHandler
    }

    /// Convenience initializer with default dependencies
    convenience init(modelContext: ModelContext) {
        let repository = PaymentRepository(supabaseClient: supabaseClient, modelContext: modelContext)
        let syncService = DefaultPaymentSyncService(repository: repository)
        let notificationService = NotificationManagerAdapter()
        let calendarService = EventKitManagerAdapter()
        let paymentOperations = DefaultPaymentOperationsService(
            modelContext: modelContext,
            syncService: syncService,
            notificationService: notificationService,
            calendarService: calendarService,
            paymentSyncManager: PaymentSyncManager(errorHandler: ErrorHandler())
        )

        self.init(modelContext: modelContext, paymentOperations: paymentOperations, errorHandler: ErrorHandler())
    }

    // MARK: - Actions

    func savePayment(onSuccess: @escaping () -> Void) {
        // Validate
        guard isValid else {
            logger.warning("⚠️ Invalid payment data")
            errorHandler.handle(PaymentError.invalidAmount)
            return
        }

        guard let amountValue = amountValue else {
            errorHandler.handle(PaymentError.invalidAmount)
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Create payment
        let payment = Payment(
            name: name,
            amount: amountValue,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            currency: currency
        )

        // Delegate to PaymentOperationsService (SRP)
        Task {
            do {
                try await paymentOperations.createPayment(payment)
                logger.info("✅ Payment created: \(payment.name)")

                // Clear form
                clearForm()

                // Call success callback
                onSuccess()
            } catch {
                logger.error("❌ Failed to save payment: \(error.localizedDescription)")
                errorHandler.handle(PaymentError.saveFailed(error))
            }
        }
    }

    func clearForm() {
        name = ""
        amount = ""
        currency = .pen
        dueDate = Date()
        category = .servicios
    }
}
