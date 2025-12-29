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

    // MARK: - Validation

    var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    var amountValue: Double? {
        Double(amount)
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

        guard let amountValue = amountValue else {
            showValidationError("El monto debe ser mayor a cero")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Create payment entity
        let payment = PaymentEntity(
            id: UUID(),
            name: name,
            amount: amountValue,
            currency: currency,
            dueDate: dueDate,
            isPaid: false,
            category: category,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil
        )

        // Delegate to Use Case
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

    func clearForm() {
        name = ""
        amount = ""
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
