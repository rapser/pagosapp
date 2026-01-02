//
//  AddPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for AddPaymentView using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
final class AddPaymentViewModel {
    // MARK: - Observable Properties (UI State)

    var name: String = ""
    var amount: String = ""
    var amountUSD: String = ""  // For dual-currency credit cards
    var currency: Currency = .pen
    var dueDate: Date = Date()
    var category: PaymentCategory = .servicios
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies (Use Cases)

    private let createPaymentUseCase: CreatePaymentUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "AddPaymentViewModel")

    // Callback for successful creation
    var onPaymentCreated: (() -> Void)?

    // MARK: - Computed Properties

    /// Show dual-currency fields for credit cards
    var showDualCurrency: Bool {
        category == .tarjetaCredito
    }

    /// Check if dual-currency payment (both PEN and USD)
    var isDualCurrencyPayment: Bool {
        guard category == .tarjetaCredito else { return false }
        let hasPEN = !amount.isEmpty && (Double(amount) ?? 0) > 0
        let hasUSD = !amountUSD.isEmpty && (Double(amountUSD) ?? 0) > 0
        return hasPEN && hasUSD
    }

    // MARK: - Validation

    var isValid: Bool {
        guard !name.isEmpty else { return false }

        if showDualCurrency {
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

    // MARK: - Initialization

    init(createPaymentUseCase: CreatePaymentUseCase) {
        self.createPaymentUseCase = createPaymentUseCase
    }

    // MARK: - Actions

    func savePayment() async {
        // Validate
        guard isValid else {
            logger.warning("⚠️ Invalid payment data")
            showValidationError("Por favor completa todos los campos correctamente")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Check if dual-currency payment (credit card with both PEN and USD)
        if isDualCurrencyPayment {
            await saveDualCurrencyPayment()
        } else {
            await saveSinglePayment()
        }
    }

    /// Save single currency payment
    private func saveSinglePayment() async {
        // Determine currency and amount
        let finalCurrency: Currency
        let finalAmount: Double

        if let penAmount = amountValue, penAmount > 0 {
            finalCurrency = .pen
            finalAmount = penAmount
        } else if let usdAmount = amountUSDValue, usdAmount > 0 {
            finalCurrency = .usd
            finalAmount = usdAmount
        } else {
            showValidationError("El monto debe ser mayor a cero")
            return
        }

        let payment = Payment(
            id: UUID(),
            name: name,
            amount: finalAmount,
            currency: finalCurrency,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: nil
        )

        let result = await createPaymentUseCase.execute(payment)

        switch result {
        case .success:
            logger.info("✅ Payment created: \(payment.name)")
            clearForm()
            onPaymentCreated?()

        case .failure(let error):
            logger.error("❌ Failed to save payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    /// Save dual-currency grouped payment (PEN + USD)
    private func saveDualCurrencyPayment() async {
        guard let penAmount = amountValue,
              let usdAmount = amountUSDValue,
              penAmount > 0,
              usdAmount > 0 else {
            showValidationError("Ambos montos deben ser mayores a cero")
            return
        }

        // Generate shared groupId for linking both payments
        let sharedGroupId = UUID()

        // Create PEN payment
        let paymentPEN = Payment(
            id: UUID(),
            name: name,
            amount: penAmount,
            currency: .pen,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: sharedGroupId
        )

        // Create USD payment
        let paymentUSD = Payment(
            id: UUID(),
            name: name,
            amount: usdAmount,
            currency: .usd,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: sharedGroupId
        )

        // Save both payments
        let resultPEN = await createPaymentUseCase.execute(paymentPEN)
        let resultUSD = await createPaymentUseCase.execute(paymentUSD)

        switch (resultPEN, resultUSD) {
        case (.success, .success):
            logger.info("✅ Dual-currency payment created: \(self.name) (PEN: \(penAmount), USD: \(usdAmount))")
            clearForm()
            onPaymentCreated?()

        case (.failure(let error), _), (_, .failure(let error)):
            logger.error("❌ Failed to save dual-currency payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    func clearForm() {
        name = ""
        amount = ""
        amountUSD = ""
        currency = .pen
        dueDate = Date()
        category = .servicios
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
        case .saveFailed(let details):
            errorMessage = "No se pudo guardar el pago: \(details)"
        default:
            errorMessage = "Ocurrió un error al guardar el pago"
        }
        showError = true
    }
}
