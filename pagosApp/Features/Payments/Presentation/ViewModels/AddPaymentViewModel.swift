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
    private let mapper: PaymentUIMapping
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
    
    /// UI-level validation for immediate user feedback
    /// Note: This is separate from PaymentValidator in Use Cases.
    /// - ViewModel validation: Fast, UI-focused, for enabling/disabling buttons
    /// - Use Case validation: Business rules, data integrity, server-side rules
    /// Both validations serve different purposes and are intentionally duplicated.
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

    init(createPaymentUseCase: CreatePaymentUseCase, mapper: PaymentUIMapping) {
        self.createPaymentUseCase = createPaymentUseCase
        self.mapper = mapper
    }

    // MARK: - Private Helpers

    /// Create a PaymentUI with common properties
    private func createPaymentUI(amount: Double, currency: Currency, groupId: UUID? = nil) -> PaymentUI {
        PaymentUI(
            id: UUID(),
            name: name,
            amount: amount,
            currency: currency,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: groupId
        )
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

        let paymentUI = createPaymentUI(amount: finalAmount, currency: finalCurrency)

        // Convert to Domain and execute
        let result = await createPaymentUseCase.execute(mapper.toDomain(paymentUI))

        switch result {
        case .success:
            logger.info("✅ Payment created: \(paymentUI.name)")
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

        // Create PEN and USD payments using helper method
        let paymentPEN_UI = createPaymentUI(amount: penAmount, currency: .pen, groupId: sharedGroupId)
        let paymentUSD_UI = createPaymentUI(amount: usdAmount, currency: .usd, groupId: sharedGroupId)

        // Convert to Domain and save both payments
        let resultPEN = await createPaymentUseCase.execute(mapper.toDomain(paymentPEN_UI))
        let resultUSD = await createPaymentUseCase.execute(mapper.toDomain(paymentUSD_UI))

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
        case .invalidName:
            errorMessage = "El nombre del pago es requerido"
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
