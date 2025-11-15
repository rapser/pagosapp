//
//  EditPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for EditPaymentView following MVVM architecture
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

@MainActor
class EditPaymentViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var name: String
    @Published var amount: String
    @Published var dueDate: Date
    @Published var category: PaymentCategory
    @Published var isPaid: Bool
    @Published var isLoading = false

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let payment: Payment
    private let modelContext: ModelContext
    private let paymentOperations: PaymentOperationsService
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
        !Calendar.current.isDate(dueDate, inSameDayAs: payment.dueDate) ||
        category != payment.category ||
        isPaid != payment.isPaid
    }

    // MARK: - Initialization (DIP: inject dependencies)

    init(payment: Payment, modelContext: ModelContext, paymentOperations: PaymentOperationsService) {
        self.payment = payment
        self.modelContext = modelContext
        self.paymentOperations = paymentOperations

        // Initialize with current payment values
        self.name = payment.name
        self.amount = String(format: "%.2f", payment.amount)
        self.dueDate = payment.dueDate
        self.category = payment.category
        self.isPaid = payment.isPaid
    }

    /// Convenience initializer with default dependencies
    convenience init(payment: Payment, modelContext: ModelContext) {
        let syncService = SupabasePaymentSyncService(client: supabaseClient)
        let notificationService = NotificationManagerAdapter()
        let calendarService = EventKitManagerAdapter()
        let paymentOperations = DefaultPaymentOperationsService(
            modelContext: modelContext,
            syncService: syncService,
            notificationService: notificationService,
            calendarService: calendarService
        )

        self.init(payment: payment, modelContext: modelContext, paymentOperations: paymentOperations)
    }

    // MARK: - Actions

    func saveChanges(onSuccess: @escaping () -> Void) {
        // Validate
        guard isValid else {
            logger.warning("⚠️ Invalid payment data")
            ErrorHandler.shared.handle(PaymentError.invalidAmount)
            return
        }

        guard let amountValue = amountValue else {
            ErrorHandler.shared.handle(PaymentError.invalidAmount)
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
                ErrorHandler.shared.handle(PaymentError.updateFailed(error))
            }
        }
    }

    func togglePaidStatus() {
        isPaid.toggle()
    }

    func resetChanges() {
        name = payment.name
        amount = String(format: "%.2f", payment.amount)
        dueDate = payment.dueDate
        category = payment.category
        isPaid = payment.isPaid
    }
}
