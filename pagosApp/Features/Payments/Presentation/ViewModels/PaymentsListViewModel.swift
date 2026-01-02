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
                // Sync notifications trigger silent refresh (no loading indicator)
                await fetchPayments(showLoading: false)
            }
        }
    }

    // MARK: - Data Operations

    /// Fetch all payments from repository (reads from local SwiftData - fast)
    /// - Parameter showLoading: Whether to show loading indicator (default: true). Set to false for silent background refreshes.
    func fetchPayments(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        defer {
            if showLoading {
                isLoading = false
            }
        }

        let result = await getAllPaymentsUseCase.execute()

        switch result {
        case .success(let fetchedPayments):
            // Convert Domain -> UI
            payments = fetchedPayments.toUI()
            logger.info("✅ Fetched \(fetchedPayments.count) payments from local storage (showLoading: \(showLoading))")

        case .failure(let error):
            logger.error("❌ Failed to fetch payments: \(error.errorCode)")
            showError(for: error)
        }
    }

    /// Delete a payment with optimistic UI update
    func deletePayment(_ payment: PaymentUI) async {
        // Optimistic update - remove from UI immediately
        payments.removeAll { $0.id == payment.id }

        // Perform actual delete in background
        let result = await deletePaymentUseCase.execute(paymentId: payment.id)

        switch result {
        case .success:
            logger.info("✅ Payment deleted: \(payment.name)")
            // SwiftData notification will sync final state

        case .failure(let error):
            logger.error("❌ Failed to delete payment: \(error.errorCode)")
            // Revert optimistic delete on failure - re-add payment
            payments.append(payment)
            showError(for: error)
        }
    }

    /// Toggle payment status with optimistic UI update
    func togglePaymentStatus(_ payment: PaymentUI) async {
        // Optimistic update - update UI immediately for instant feedback
        if let index = payments.firstIndex(where: { $0.id == payment.id }) {
            let updatedPayment = PaymentUI(
                id: payment.id,
                name: payment.name,
                amount: payment.amount,
                currency: payment.currency,
                dueDate: payment.dueDate,
                isPaid: !payment.isPaid,  // Toggle immediately
                category: payment.category,
                eventIdentifier: payment.eventIdentifier,
                syncStatus: payment.syncStatus,
                lastSyncedAt: payment.lastSyncedAt
            )
            payments[index] = updatedPayment
        }

        // Perform actual update in background (no loading state to avoid flicker)
        let result = await togglePaymentStatusUseCase.execute(payment.toDomain())

        switch result {
        case .success(let updatedPayment):
            logger.info("✅ Payment status updated: \(updatedPayment.name) - isPaid: \(updatedPayment.isPaid)")
            // SwiftData notification will sync if there are differences

        case .failure(let error):
            logger.error("❌ Failed to update payment status: \(error.errorCode)")
            // Revert optimistic update on failure
            if let index = payments.firstIndex(where: { $0.id == payment.id }) {
                payments[index] = payment
            }
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
