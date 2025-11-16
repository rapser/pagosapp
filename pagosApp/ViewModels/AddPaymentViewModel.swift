//
//  AddPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for AddPaymentView following MVVM architecture
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

@MainActor
class AddPaymentViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var name: String = ""
    @Published var amount: String = ""
    @Published var dueDate: Date = Date()
    @Published var category: PaymentCategory = .servicios
    @Published var isLoading = false

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let modelContext: ModelContext
    private let paymentOperations: PaymentOperationsService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "AddPaymentViewModel")

    // MARK: - Validation

    var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    var amountValue: Double? {
        Double(amount)
    }

    // MARK: - Initialization (DIP: inject dependencies)

    init(modelContext: ModelContext, paymentOperations: PaymentOperationsService) {
        self.modelContext = modelContext
        self.paymentOperations = paymentOperations
    }

    /// Convenience initializer with default dependencies
    convenience init(modelContext: ModelContext) {
        let syncService = SupabasePaymentSyncService(client: supabaseClient)
        let notificationService = NotificationManagerAdapter()
        let calendarService = EventKitManagerAdapter()
        let paymentOperations = DefaultPaymentOperationsService(
            modelContext: modelContext,
            syncService: syncService,
            notificationService: notificationService,
            calendarService: calendarService
        )

        self.init(modelContext: modelContext, paymentOperations: paymentOperations)
    }

    // MARK: - Actions

    func savePayment(onSuccess: @escaping () -> Void) {
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

        isLoading = true
        defer { isLoading = false }

        // Create payment
        let payment = Payment(
            name: name,
            amount: amountValue,
            dueDate: dueDate,
            isPaid: false,
            category: category
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
                ErrorHandler.shared.handle(PaymentError.saveFailed(error))
            }
        }
    }

    func clearForm() {
        name = ""
        amount = ""
        dueDate = Date()
        category = .servicios
    }
}
