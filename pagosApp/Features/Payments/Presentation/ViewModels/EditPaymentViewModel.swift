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

    private let paymentEntity: Payment
    private let updatePaymentUseCase: UpdatePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
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
        name != paymentEntity.name ||
        amountValue != paymentEntity.amount ||
        currency != paymentEntity.currency ||
        !Calendar.current.isDate(dueDate, inSameDayAs: paymentEntity.dueDate) ||
        category != paymentEntity.category ||
        isPaid != paymentEntity.isPaid
    }

    // MARK: - Initialization

    init(
        payment: Payment,
        updatePaymentUseCase: UpdatePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    ) {
        self.paymentEntity = payment
        self.updatePaymentUseCase = updatePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase

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

        // Create updated payment entity
        let updatedPayment = Payment(
            id: paymentEntity.id,
            name: name,
            amount: amountValue,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentEntity.eventIdentifier,
            syncStatus: paymentEntity.syncStatus,
            lastSyncedAt: paymentEntity.lastSyncedAt
        )

        // Delegate to Use Case
        let result = await updatePaymentUseCase.execute(updatedPayment)

        switch result {
        case .success:
            logger.info("✅ Payment updated: \(updatedPayment.name)")
            onPaymentUpdated?()
            onSuccess?()

        case .failure(let error):
            logger.error("❌ Failed to update payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    func resetChanges() {
        // Reset to original payment values
        self.name = paymentEntity.name
        self.amount = String(format: "%.2f", paymentEntity.amount)
        self.currency = paymentEntity.currency
        self.dueDate = paymentEntity.dueDate
        self.category = paymentEntity.category
        self.isPaid = paymentEntity.isPaid
    }

    func togglePaidStatus() async {
        isLoading = true
        defer { isLoading = false }

        // Create current payment entity with current UI values
        let currentPayment = Payment(
            id: paymentEntity.id,
            name: name,
            amount: amountValue ?? paymentEntity.amount,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentEntity.eventIdentifier,
            syncStatus: paymentEntity.syncStatus,
            lastSyncedAt: paymentEntity.lastSyncedAt
        )

        // Delegate to Use Case
        let result = await togglePaymentStatusUseCase.execute(currentPayment)

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
