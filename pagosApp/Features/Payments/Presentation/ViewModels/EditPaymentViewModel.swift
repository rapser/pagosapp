//
//  EditPaymentViewModel.swift
//  pagosApp
//
//  ViewModel for EditPaymentView using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class EditPaymentViewModel: BaseViewModel {
    // MARK: - Observable Properties (UI State)

    var name: String
    var amount: String      // Always PEN field
    var amountUSD: String   // Always USD field
    var currency: Currency
    var dueDate: Date
    var category: PaymentCategory
    var isPaid: Bool

    // MARK: - Dependencies (Use Cases)

    private let paymentUI: PaymentUI
    private let otherPaymentUI: PaymentUI?  // The other payment in the group (PEN or USD)
    private let createPaymentUseCase: CreatePaymentUseCase
    private let updatePaymentUseCase: UpdatePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let mapper: PaymentUIMapping

    // Callback for successful update
    var onPaymentUpdated: (() -> Void)?

    // MARK: - Computed Properties

    /// True if this is a credit card payment — always shows dual-currency fields
    var isDualCurrencyPayment: Bool {
        category == .tarjetaCredito
    }

    /// True if this payment already has a linked sibling (fully grouped dual-currency)
    var isGroupedDualCurrency: Bool {
        otherPaymentUI != nil && category == .tarjetaCredito
    }

    // MARK: - Validation

    /// UI-level validation for immediate user feedback
    /// Note: This is separate from PaymentValidator in Use Cases.
    /// - ViewModel validation: Fast, UI-focused, for enabling/disabling buttons
    /// - Use Case validation: Business rules, data integrity, server-side rules
    /// Both validations serve different purposes and are intentionally duplicated.
    var isValid: Bool {
        guard !name.isEmpty else { return false }

        if isDualCurrencyPayment {
            // For credit cards, need at least one amount
            let hasPEN = !amount.isEmpty && (Double(amount) ?? 0) > 0
            let hasUSD = !amountUSD.isEmpty && (Double(amountUSD) ?? 0) > 0
            return hasPEN || hasUSD
        } else {
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

        if isGroupedDualCurrency, let otherPayment = otherPaymentUI {
            // Already grouped: compare both amounts against their respective payments
            let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
            let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment
            let penChanged = amountValue != penPayment.amount
            let usdChanged = amountUSDValue != usdPayment.amount
            return nameChanged || penChanged || usdChanged || dateChanged || categoryChanged || paidChanged
        } else if isDualCurrencyPayment {
            // Single TC: detect if user modified existing amount or added a second currency
            if paymentUI.currency == .pen {
                let penChanged = amountValue != paymentUI.amount
                let newUSDAdded = (Double(amountUSD) ?? 0) > 0
                return nameChanged || penChanged || newUSDAdded || dateChanged || categoryChanged || paidChanged
            } else {
                let usdChanged = amountUSDValue != paymentUI.amount
                let newPENAdded = (Double(amount) ?? 0) > 0
                return nameChanged || usdChanged || newPENAdded || dateChanged || categoryChanged || paidChanged
            }
        } else {
            // Non-TC single currency
            let amountChanged = amountValue != paymentUI.amount
            let currencyChanged = currency != paymentUI.currency
            return nameChanged || amountChanged || currencyChanged || dateChanged || categoryChanged || paidChanged
        }
    }

    // MARK: - Initialization

    init(
        payment: PaymentUI,
        otherPayment: PaymentUI? = nil,
        createPaymentUseCase: CreatePaymentUseCase,
        updatePaymentUseCase: UpdatePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase,
        mapper: PaymentUIMapping
    ) {
        self.paymentUI = payment
        self.otherPaymentUI = otherPayment
        self.createPaymentUseCase = createPaymentUseCase
        self.updatePaymentUseCase = updatePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase
        self.mapper = mapper

        self.name = payment.name
        self.currency = payment.currency

        if let otherPayment = otherPayment, payment.category == .tarjetaCredito {
            // Already grouped dual-currency: map PEN→amount, USD→amountUSD
            let penPayment = payment.currency == .pen ? payment : otherPayment
            let usdPayment = payment.currency == .usd ? payment : otherPayment
            self.amount = String(format: "%.2f", penPayment.amount)
            self.amountUSD = String(format: "%.2f", usdPayment.amount)
        } else if payment.category == .tarjetaCredito {
            // Single TC: show each currency in its correct field, leave other empty
            if payment.currency == .pen {
                self.amount = String(format: "%.2f", payment.amount)
                self.amountUSD = ""
            } else {
                self.amount = ""
                self.amountUSD = String(format: "%.2f", payment.amount)
            }
        } else {
            self.amount = String(format: "%.2f", payment.amount)
            self.amountUSD = ""
        }

        self.dueDate = payment.dueDate
        self.category = payment.category
        self.isPaid = payment.isPaid
        super.init(category: "EditPaymentViewModel")
    }

    // MARK: - Actions

    func saveChanges(onSuccess: (() -> Void)? = nil) async {
        guard isValid else {
            setValidationError(L10n.Payments.Validation.completeFields)
            return
        }

        guard hasChanges else { return }

        isLoading = true
        defer { isLoading = false }

        if isGroupedDualCurrency, let otherPayment = otherPaymentUI {
            // Already grouped: update both payments
            await saveDualCurrencyPayment(otherPayment: otherPayment, onSuccess: onSuccess)
        } else if isDualCurrencyPayment {
            let hasPEN = (amountValue ?? 0) > 0
            let hasUSD = (amountUSDValue ?? 0) > 0
            if hasPEN && hasUSD {
                // User added a second currency: upgrade to grouped
                await saveUpgradingToGrouped(onSuccess: onSuccess)
            } else {
                // Only one currency filled: update existing single payment
                await saveSinglePayment(onSuccess: onSuccess)
            }
        } else {
            await saveSinglePayment(onSuccess: onSuccess)
        }
    }

    /// Save single-currency payment (non-TC or TC with only one amount)
    private func saveSinglePayment(onSuccess: (() -> Void)?) async {
        let finalAmount: Double
        let finalCurrency: Currency

        if isDualCurrencyPayment && !isGroupedDualCurrency {
            // TC single: use the field that has a value
            if let penAmt = amountValue, penAmt > 0 {
                finalAmount = penAmt
                finalCurrency = .pen
            } else if let usdAmt = amountUSDValue, usdAmt > 0 {
                finalAmount = usdAmt
                finalCurrency = .usd
            } else {
                setValidationError(L10n.Payments.Validation.amountGreaterZero)
                return
            }
        } else {
            guard let amt = amountValue else {
                setValidationError(L10n.Payments.Validation.amountGreaterZero)
                return
            }
            finalAmount = amt
            finalCurrency = currency
        }

        let updatedPaymentUI = PaymentUI(
            id: paymentUI.id,
            name: name,
            amount: finalAmount,
            currency: finalCurrency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentUI.eventIdentifier,
            syncStatus: paymentUI.syncStatus,
            lastSyncedAt: paymentUI.lastSyncedAt,
            groupId: paymentUI.groupId
        )

        let result = await updatePaymentUseCase.execute(mapper.toDomain(updatedPaymentUI))

        switch result {
        case .success:
            onPaymentUpdated?()
            onSuccess?()

        case .failure(let error):
            logDebug("Failed to update payment: \(error.errorCode)")
            setError(PaymentErrorMessageMapper.message(for: error))
        }
    }

    /// Save dual-currency grouped payment (PEN + USD) — both already exist
    private func saveDualCurrencyPayment(otherPayment: PaymentUI, onSuccess: (() -> Void)?) async {
        // amount is always PEN, amountUSD is always USD
        guard let penAmountValue = amountValue, penAmountValue > 0,
              let usdAmountValue = amountUSDValue, usdAmountValue > 0 else {
            setValidationError(L10n.Payments.Validation.bothAmountsGreaterZero)
            return
        }

        let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
        let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment

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

        let resultPEN = await updatePaymentUseCase.execute(mapper.toDomain(updatedPENPayment))
        let resultUSD = await updatePaymentUseCase.execute(mapper.toDomain(updatedUSDPayment))

        switch (resultPEN, resultUSD) {
        case (.success, .success):
            onPaymentUpdated?()
            onSuccess?()

        case (.failure(let error), _), (_, .failure(let error)):
            logDebug("Failed to update dual-currency payment: \(error.errorCode)")
            setError(PaymentErrorMessageMapper.message(for: error))
        }
    }

    /// Upgrade a single-currency TC payment to a grouped dual-currency payment
    /// by creating a new sibling record and linking both via a shared groupId.
    private func saveUpgradingToGrouped(onSuccess: (() -> Void)?) async {
        guard let penAmt = amountValue, penAmt > 0,
              let usdAmt = amountUSDValue, usdAmt > 0 else { return }

        let sharedGroupId = UUID()

        // Update existing payment: assign groupId and refresh shared fields
        let existingAmount = paymentUI.currency == .pen ? penAmt : usdAmt
        let updatedExisting = PaymentUI(
            id: paymentUI.id,
            name: name,
            amount: existingAmount,
            currency: paymentUI.currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: paymentUI.eventIdentifier,
            syncStatus: paymentUI.syncStatus,
            lastSyncedAt: paymentUI.lastSyncedAt,
            groupId: sharedGroupId
        )

        // Create new payment for the other currency
        let newCurrency: Currency = paymentUI.currency == .pen ? .usd : .pen
        let newAmount = newCurrency == .usd ? usdAmt : penAmt
        let newPayment = PaymentUI(
            id: UUID(),
            name: name,
            amount: newAmount,
            currency: newCurrency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: sharedGroupId
        )

        let updateResult = await updatePaymentUseCase.execute(mapper.toDomain(updatedExisting))
        switch updateResult {
        case .failure(let error):
            logDebug("Failed to update existing payment when upgrading to group: \(error.errorCode)")
            setError(PaymentErrorMessageMapper.message(for: error))
            return
        case .success:
            break
        }

        let createResult = await createPaymentUseCase.execute(mapper.toDomain(newPayment))
        switch createResult {
        case .success:
            onPaymentUpdated?()
            onSuccess?()
        case .failure(let error):
            logDebug("Failed to create sibling payment when upgrading to group: \(error.errorCode)")
            setError(PaymentErrorMessageMapper.message(for: error))
        }
    }

    func resetChanges() {
        self.name = paymentUI.name
        self.currency = paymentUI.currency

        if let otherPayment = otherPaymentUI, category == .tarjetaCredito {
            let penPayment = paymentUI.currency == .pen ? paymentUI : otherPayment
            let usdPayment = paymentUI.currency == .usd ? paymentUI : otherPayment
            self.amount = String(format: "%.2f", penPayment.amount)
            self.amountUSD = String(format: "%.2f", usdPayment.amount)
        } else if category == .tarjetaCredito {
            if paymentUI.currency == .pen {
                self.amount = String(format: "%.2f", paymentUI.amount)
                self.amountUSD = ""
            } else {
                self.amount = ""
                self.amountUSD = String(format: "%.2f", paymentUI.amount)
            }
        } else {
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

        let result = await togglePaymentStatusUseCase.execute(mapper.toDomain(currentPaymentUI))

        switch result {
        case .success(let updatedPayment):
            isPaid = updatedPayment.isPaid
            onPaymentUpdated?()

        case .failure(let error):
            logDebug("Failed to toggle payment status: \(error.errorCode)")
            setError(PaymentErrorMessageMapper.message(for: error))
        }
    }
}
