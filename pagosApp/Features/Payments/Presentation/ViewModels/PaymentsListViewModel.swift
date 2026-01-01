//
//  PaymentsListViewModel.swift
//  pagosApp
//
//  ViewModel for PaymentsListView using Clean Architecture
//  Uses Use Cases instead of direct repository/service access
//

import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
final class PaymentsListViewModel {
    // MARK: - Observable Properties (UI State)

    var payments: [PaymentUI] = []
    var selectedFilter: PaymentFilter = .currentMonth
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies (Use Cases)

    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let deletePaymentUseCase: DeletePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentsListViewModel")

    // MARK: - Computed Properties

    var filteredPayments: [PaymentUI] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .currentMonth:
            return payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
        case .futureMonths:
            // Get the first day of next month
            guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfCurrentMonth) else {
                logger.error("❌ Failed to calculate next month date")
                return []
            }
            return payments.filter { $0.dueDate >= startOfNextMonth }
        }
    }

    // MARK: - Initialization

    init(
        getAllPaymentsUseCase: GetAllPaymentsUseCase,
        deletePaymentUseCase: DeletePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    ) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.deletePaymentUseCase = deletePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase

        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("PaymentsDidSync")) {
                await fetchPayments()
            }
        }
    }

    // MARK: - Data Operations

    /// Fetch all payments from repository
    func fetchPayments() async {
        isLoading = true
        defer { isLoading = false }

        let result = await getAllPaymentsUseCase.execute()

        switch result {
        case .success(let fetchedPayments):
            // Convert Domain -> UI
            payments = fetchedPayments.toUI()
            logger.info("✅ Fetched \(fetchedPayments.count) payments")

        case .failure(let error):
            logger.error("❌ Failed to fetch payments: \(error.errorCode)")
            showError(for: error)
        }
    }

    /// Delete a payment
    func deletePayment(_ payment: PaymentUI) async {
        isLoading = true
        defer { isLoading = false }

        let result = await deletePaymentUseCase.execute(paymentId: payment.id)

        switch result {
        case .success:
            logger.info("✅ Payment deleted: \(payment.name)")
            // Removed fetchPayments() - SwiftData notification will trigger automatic update

        case .failure(let error):
            logger.error("❌ Failed to delete payment: \(error.errorCode)")
            showError(for: error)
        }
    }

    /// Toggle payment status
    func togglePaymentStatus(_ payment: PaymentUI) async {
        isLoading = true
        defer { isLoading = false }

        // Convert UI -> Domain for Use Case
        let result = await togglePaymentStatusUseCase.execute(payment.toDomain())

        switch result {
        case .success(let updatedPayment):
            logger.info("✅ Payment status updated: \(updatedPayment.name) - isPaid: \(updatedPayment.isPaid)")
            // Removed fetchPayments() - SwiftData notification will trigger automatic update

        case .failure(let error):
            logger.error("❌ Failed to update payment status: \(error.errorCode)")
            showError(for: error)
        }
    }

    /// Refresh data
    func refresh() async {
        await fetchPayments()
    }

    // MARK: - Error Handling

    private func showError(for error: PaymentError) {
        switch error {
        case .deleteFailed(let details):
            errorMessage = "No se pudo eliminar el pago: \(details)"
        case .updateFailed(let details):
            errorMessage = "No se pudo actualizar el pago: \(details)"
        case .unknown(let details):
            errorMessage = "Error: \(details)"
        default:
            errorMessage = "Ocurrió un error inesperado"
        }
        showError = true
    }
}
