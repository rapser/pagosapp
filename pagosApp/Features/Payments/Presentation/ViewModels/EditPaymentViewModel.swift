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
    var amountUSD: String  // For dual-currency credit cards
    var currency: Currency
    var dueDate: Date
    var category: PaymentCategory
    var isPaid: Bool
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies (Use Cases)

    private let paymentUI: PaymentUI
    private let otherPaymentUI: PaymentUI?  // The other payment in the group (PEN or USD)
    private let updatePaymentUseCase: UpdatePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let mapper: PaymentUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "EditPaymentViewModel")

    // Callback for successful update
    var onPaymentUpdated: (() -> Void)?

    // MARK: - Computed Properties

    /// Check if this is a dual-currency grouped payment
    var isDualCurrencyPayment: Bool {
        otherPaymentUI != nil && category == .tarjetaCredito
    }

    // MARK: - Validation

    var isValid: Bool {
        guard !name.isEmpty else { return false }
        
        if isDualCurrencyPayment {
            // For credit cards, need at least one amount
            let hasPEN = !amount.isEmpty && (Double(amount) ?? 0) > 0
            let hasUSD = !amountUSD.isEmpty && (Double(amountUSD) ?? 0) > 0
            return hasPEN || hasUSD
        } else {
            // For other categories, require primary amount
            return !amount.isEmpty && (Double(amount) ?? 0) > 0
        }
    }

    var amountValue: Double? {
        Double(amount)
    }

    var amountUSDValue: Double? {
        Double(amountUSD)
    }

    var hasChanges: Bool {
        let nameChanged = name != paymentUI.name
        let dateChanged = !Calendar.current.isDate(dueDate, inSameDayAs: paymentUI.dueDate)
        let categoryChanged = category != paymentUI.category
        let paidChanged = isPaid != paymentUI.isPaid
        
        if isDualCurrencyPayment, let otherPayment = otherPaymentUI {
            // For dual-currency, check both amounts
            // Always compare amount with PEN payment and amountUSD with USD payment
            let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
            let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment
            let penChanged = amountValue != penPayment.amount
            let usdChanged = amountUSDValue != usdPayment.amount
            return nameChanged || penChanged || usdChanged || dateChanged || categoryChanged || paidChanged
        } else {
            // For single currency
            let amountChanged = amountValue != paymentUI.amount
            let currencyChanged = currency != paymentUI.currency
            return nameChanged || amountChanged || currencyChanged || dateChanged || categoryChanged || paidChanged
        }
    }

    // MARK: - Initialization

    init(
        payment: PaymentUI,
        otherPayment: PaymentUI? = nil,
        updatePaymentUseCase: UpdatePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase,
        mapper: PaymentUIMapping
    ) {
        self.paymentUI = payment
        self.otherPaymentUI = otherPayment
        self.updatePaymentUseCase = updatePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase
        self.mapper = mapper

        // Initialize with current payment values
        self.name = payment.name
        self.currency = payment.currency
        
        // For dual-currency payments, initialize both amounts
        // Always use amount for PEN and amountUSD for USD, regardless of which payment is primary
        if let otherPayment = otherPayment, payment.category == .tarjetaCredito {
            let penPayment = payment.currency == .pen ? payment : otherPayment
            let usdPayment = payment.currency == .usd ? payment : otherPayment
            self.amount = String(format: "%.2f", penPayment.amount)
            self.amountUSD = String(format: "%.2f", usdPayment.amount)
        } else {
            // Single currency payment
            self.amount = String(format: "%.2f", payment.amount)
            self.amountUSD = ""
        }
        
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

        guard hasChanges else {
            logger.info("ℹ️ No changes to save")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Check if dual-currency payment (credit card with both PEN and USD)
        if isDualCurrencyPayment, let otherPayment = otherPaymentUI {
            await saveDualCurrencyPayment(otherPayment: otherPayment, onSuccess: onSuccess)
        } else {
            await saveSinglePayment(onSuccess: onSuccess)
        }
    }

    /// Save single currency payment
    private func saveSinglePayment(onSuccess: (() -> Void)?) async {
        guard let amountValue = amountValue else {
            showValidationError("El monto debe ser mayor a cero")
            return
        }

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

    /// Save dual-currency grouped payment (PEN + USD)
    private func saveDualCurrencyPayment(otherPayment: PaymentUI, onSuccess: (() -> Void)?) async {
        // amount is always PEN, amountUSD is always USD
        guard let penAmountValue = amountValue, penAmountValue > 0,
              let usdAmountValue = amountUSDValue, usdAmountValue > 0 else {
            showValidationError("Ambos montos deben ser mayores a cero")
            return
        }

        // Determine which payment is PEN and which is USD
        let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
        let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment

        // Create updated payment UI models
        let updatedPENPayment = PaymentUI(
            id: penPayment.id,
            name: name,
            amount: penAmountValue,
            currency: .pen,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: penPayment.eventIdentifier,
            syncStatus: penPayment.syncStatus,
            lastSyncedAt: penPayment.lastSyncedAt,
            groupId: paymentUI.groupId
        )

        let updatedUSDPayment = PaymentUI(
            id: usdPayment.id,
            name: name,
            amount: usdAmountValue,
            currency: .usd,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: usdPayment.eventIdentifier,
            syncStatus: usdPayment.syncStatus,
            lastSyncedAt: usdPayment.lastSyncedAt,
            groupId: paymentUI.groupId
        )

        // Convert to Domain and save both payments
        let resultPEN = await updatePaymentUseCase.execute(mapper.toDomain(updatedPENPayment))
        let resultUSD = await updatePaymentUseCase.execute(mapper.toDomain(updatedUSDPayment))

        switch (resultPEN, resultUSD) {
        case (.success, .success):
            logger.info("✅ Dual-currency payment updated: \(self.name) (PEN: \(penAmountValue), USD: \(usdAmountValue))")
            onPaymentUpdated?()
            onSuccess?()

        case (.failure(let error), _), (_, .failure(let error)):
            logger.error("❌ Failed to update dual-currency payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    func resetChanges() {
        // Reset to original payment values
        self.name = paymentUI.name
        self.currency = paymentUI.currency
        
        // For dual-currency payments, reset both amounts
        // Always use amount for PEN and amountUSD for USD, regardless of which payment is primary
        if let otherPayment = otherPaymentUI, category == .tarjetaCredito {
            let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
            let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment
            self.amount = String(format: "%.2f", penPayment.amount)
            self.amountUSD = String(format: "%.2f", usdPayment.amount)
        } else {
            // Single currency payment
            self.amount = String(format: "%.2f", paymentUI.amount)
            self.amountUSD = ""
        }
        
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
