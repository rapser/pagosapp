//
//  EditPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for EditPaymentView using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
final class EditPaymentViewModel {
    // MARK: - Observable Properties (UI State)

    var name: String
    var amount: String
    var currency: Currency
    var dueDate: Date
    var category: PaymentCategory
    var isPaid: Bool
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies (Use Cases)

    private let paymentUI: PaymentUI
    private let updatePaymentUseCase: UpdatePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let mapper: PaymentUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "EditPaymentViewModel")

    // Callback for successful update
    var onPaymentUpdated: (() -> Void)?

    // MARK: - Validation

    var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    var amountValue: Double? {
        Double(amount)
    }

    var hasChanges: Bool {
        name != paymentUI.name ||
        amountValue != paymentUI.amount ||
        currency != paymentUI.currency ||
        !Calendar.current.isDate(dueDate, inSameDayAs: paymentUI.dueDate) ||
        category != paymentUI.category ||
        isPaid != paymentUI.isPaid
    }

    // MARK: - Initialization

    init(
        payment: PaymentUI,
        updatePaymentUseCase: UpdatePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase,
        mapper: PaymentUIMapping
    ) {
        self.paymentUI = payment
        self.updatePaymentUseCase = updatePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase
        self.mapper = mapper

        // Initialize with current payment values
        self.name = payment.name
        self.amount = String(format: "%.2f", payment.amount)
        self.currency = payment.currency
        self.dueDate = payment.dueDate
        self.category = payment.category
        self.isPaid = payment.isPaid
    }

    // MARK: - Actions

    func saveChanges(onSuccess: (() -> Void)? = nil) async {
        // Validate
        guard isValid else {
            logger.warning("⚠️ Invalid payment data")
            showValidationError("Por favor completa todos los campos correctamente")
            return
        }

        guard let amountValue = amountValue else {
            showValidationError("El monto debe ser mayor a cero")
            return
        }

        guard hasChanges else {
            logger.info("ℹ️ No changes to save")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Create updated payment UI model
        let updatedPaymentUI = PaymentUI(
            id: paymentUI.id,
            name: name,
            amount: amountValue,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentUI.eventIdentifier,
            syncStatus: paymentUI.syncStatus,
            lastSyncedAt: paymentUI.lastSyncedAt,
            groupId: paymentUI.groupId
        )

        // Convert to Domain and delegate to Use Case
        let result = await updatePaymentUseCase.execute(mapper.toDomain(updatedPaymentUI))

        switch result {
        case .success:
            logger.info("✅ Payment updated: \(updatedPaymentUI.name)")
            onPaymentUpdated?()
            onSuccess?()

        case .failure(let error):
            logger.error("❌ Failed to update payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    func resetChanges() {
        // Reset to original payment values
        self.name = paymentUI.name
        self.amount = String(format: "%.2f", paymentUI.amount)
        self.currency = paymentUI.currency
        self.dueDate = paymentUI.dueDate
        self.category = paymentUI.category
        self.isPaid = paymentUI.isPaid
    }

    func togglePaidStatus() async {
        isLoading = true
        defer { isLoading = false }

        // Create current payment UI with current values
        let currentPaymentUI = PaymentUI(
            id: paymentUI.id,
            name: name,
            amount: amountValue ?? paymentUI.amount,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentUI.eventIdentifier,
            syncStatus: paymentUI.syncStatus,
            lastSyncedAt: paymentUI.lastSyncedAt,
            groupId: paymentUI.groupId
        )

        // Convert to Domain and delegate to Use Case
        let result = await togglePaymentStatusUseCase.execute(mapper.toDomain(currentPaymentUI))

        switch result {
        case .success(let updatedPayment):
            logger.info("✅ Payment status toggled: \(updatedPayment.name)")
            isPaid = updatedPayment.isPaid
            onPaymentUpdated?()

        case .failure(let error):
            logger.error("❌ Failed to toggle payment status: \(error.errorCode)")
            showError(for: error)
        }
    }

    // MARK: - Error Handling

    private func showValidationError(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func showError(for error: PaymentError) {
        switch error {
        case .invalidName:
            errorMessage = "El nombre del pago es requerido"
        case .invalidAmount:
            errorMessage = "El monto debe ser mayor a cero"
        case .invalidDate:
            errorMessage = "La fecha seleccionada no es válida"
        case .updateFailed(let details):
            errorMessage = "No se pudo actualizar el pago: \(details)"
        default:
            errorMessage = "Ocurrió un error al actualizar el pago"
        }
        showError = true
    }
}
