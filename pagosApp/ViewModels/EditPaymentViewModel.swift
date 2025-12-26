//
//  EditPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for EditPaymentView following MVVM architecture
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftUI
import SwiftData
import Observation
import OSLog

@MainActor
@Observable
final class EditPaymentViewModel {
    // MARK: - Observable Properties

    var name: String
    var amount: String
    var currency: Currency
    var dueDate: Date
    var category: PaymentCategory
    var isPaid: Bool
    var isLoading = false

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let payment: Payment
    private let modelContext: ModelContext
    private let paymentOperations: PaymentOperationsService
    private let errorHandler: ErrorHandler
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "EditPaymentViewModel")

    // MARK: - Validation

    var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    var amountValue: Double? {
        Double(amount)
    }

    var hasChanges: Bool {
        name != payment.name ||
        amountValue != payment.amount ||
        currency != payment.currency ||
        !Calendar.current.isDate(dueDate, inSameDayAs: payment.dueDate) ||
        category != payment.category ||
        isPaid != payment.isPaid
    }

    // MARK: - Initialization (DIP: inject dependencies)

    init(payment: Payment, modelContext: ModelContext, paymentOperations: PaymentOperationsService, errorHandler: ErrorHandler) {
        self.payment = payment
        self.modelContext = modelContext
        self.paymentOperations = paymentOperations
        self.errorHandler = errorHandler

        // Initialize with current payment values
        self.name = payment.name
        self.amount = String(format: "%.2f", payment.amount)
        self.currency = payment.currency
        self.dueDate = payment.dueDate
        self.category = payment.category
        self.isPaid = payment.isPaid
    }

    /// Convenience initializer with default dependencies
    convenience init(payment: Payment, modelContext: ModelContext) {
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

        self.init(payment: payment, modelContext: modelContext, paymentOperations: paymentOperations, errorHandler: ErrorHandler())
    }

    // MARK: - Actions

    func saveChanges(onSuccess: @escaping () -> Void) {
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

        guard hasChanges else {
            logger.info("ℹ️ No changes to save")
            onSuccess()
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Update payment model
        payment.name = name
        payment.amount = amountValue
        payment.currency = currency
        payment.dueDate = dueDate
        payment.category = category
        payment.isPaid = isPaid

        // Delegate to PaymentOperationsService (SRP)
        Task {
            do {
                try await paymentOperations.updatePayment(payment)
                logger.info("✅ Payment updated: \(self.payment.name)")

                // Call success callback
                onSuccess()
            } catch {
                logger.error("❌ Failed to update payment: \(error.localizedDescription)")
                errorHandler.handle(PaymentError.updateFailed(error))
            }
        }
    }

    func togglePaidStatus() {
        isPaid.toggle()
    }

    func resetChanges() {
        name = payment.name
        amount = String(format: "%.2f", payment.amount)
        currency = payment.currency
        dueDate = payment.dueDate
        category = payment.category
        isPaid = payment.isPaid
    }
}
