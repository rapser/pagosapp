//
//  AddPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for AddPaymentView using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AddPaymentViewModel: BaseViewModel {
    // MARK: - Observable Properties (UI State)

    var name: String = ""
    var amount: String = ""
    var amountUSD: String = ""  // For dual-currency credit cards
    var currency: Currency = .pen
    var dueDate: Date = Date()
    var category: PaymentCategory = .servicios

    // MARK: - Dependencies (Use Cases)

    private let createPaymentUseCase: CreatePaymentUseCase
    private let mapper: PaymentUIMapping

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
        super.init(category: "AddPaymentViewModel")
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
            setValidationError(L10n.Payments.Validation.completeFields)
            return
        }

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
            setValidationError(L10n.Payments.Validation.amountGreaterZero)
            return
        }

        let paymentUI = createPaymentUI(amount: finalAmount, currency: finalCurrency)

        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.createPaymentUseCase.execute(self.mapper.toDomain(paymentUI))
                if case .failure(let error) = result {
                    throw error
                }
                return result
            },
            onSuccess: { _ in
                self.clearForm()
                self.onPaymentCreated?()
            },
            onError: { error in
                if let paymentError = error as? PaymentError {
                    self.setError(PaymentErrorMessageMapper.message(for: paymentError))
                }
            }
        )
    }

    /// Save dual-currency grouped payment (PEN + USD)
    private func saveDualCurrencyPayment() async {
        guard let penAmount = amountValue,
              let usdAmount = amountUSDValue,
              penAmount > 0,
              usdAmount > 0 else {
            setValidationError(L10n.Payments.Validation.bothAmountsGreaterZero)
            return
        }

        // Generate shared groupId for linking both payments
        let sharedGroupId = UUID()

        // Create PEN and USD payments using helper method
        let paymentPenUI = createPaymentUI(amount: penAmount, currency: .pen, groupId: sharedGroupId)
        let paymentUsdUI = createPaymentUI(amount: usdAmount, currency: .usd, groupId: sharedGroupId)

        await withLoadingAndErrorHandling(
            operation: {
                let resultPEN = await self.createPaymentUseCase.execute(self.mapper.toDomain(paymentPenUI))
                let resultUSD = await self.createPaymentUseCase.execute(self.mapper.toDomain(paymentUsdUI))
                
                switch (resultPEN, resultUSD) {
                case (.success, .success):
                    return (resultPEN, resultUSD)
                case (.failure(let error), _), (_, .failure(let error)):
                    throw error
                }
            },
            onSuccess: { _ in
                self.clearForm()
                self.onPaymentCreated?()
            },
            onError: { error in
                if let paymentError = error as? PaymentError {
                    self.setError(PaymentErrorMessageMapper.message(for: paymentError))
                }
            }
        )
    }

    func clearForm() {
        name = ""
        amount = ""
        amountUSD = ""
        currency = .pen
        dueDate = Date()
        category = .servicios
    }
}
