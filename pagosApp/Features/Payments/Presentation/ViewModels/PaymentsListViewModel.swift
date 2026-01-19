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
    var selectedFilter: PaymentFilterUI = .currentMonth
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies (Use Cases)

    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let deletePaymentUseCase: DeletePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let mapper: PaymentUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentsListViewModel")
    
    // Track if we've already rescheduled notifications on first load
    private var hasRescheduledNotifications = false

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

    /// Group dual-currency credit card payments for display
    /// Returns sorted items (groups and individuals mixed by due date)
    var groupedPayments: [PaymentListItemUI] {
        var items: [PaymentListItemUI] = []
        var processedIds: Set<UUID> = []

        // Group payments by groupId (only for credit cards)
        let paymentsByGroupId = Dictionary(grouping: filteredPayments.filter { $0.groupId != nil }) { $0.groupId! }

        for (groupId, groupedPayments) in paymentsByGroupId {
            // Only group credit card payments
            guard groupedPayments.first?.category == .tarjetaCredito else {
                // If not credit card, treat as individuals
                for payment in groupedPayments {
                    items.append(.individual(payment))
                    processedIds.insert(payment.id)
                }
                continue
            }

            let penPayment = groupedPayments.first { $0.currency == .pen }
            let usdPayment = groupedPayments.first { $0.currency == .usd }

            // Create group
            if let group = PaymentGroupUI.from(penPayment: penPayment, usdPayment: usdPayment, groupId: groupId) {
                items.append(.group(group))
                if let pen = penPayment {
                    processedIds.insert(pen.id)
                }
                if let usd = usdPayment {
                    processedIds.insert(usd.id)
                }
            }
        }

        // Add ungrouped payments
        for payment in filteredPayments where !processedIds.contains(payment.id) {
            items.append(.individual(payment))
        }

        // Sort all items by due date
        items.sort { item1, item2 in
            let date1 = item1.dueDate
            let date2 = item2.dueDate
            return date1 < date2
        }

        return items
    }

    // MARK: - Initialization

    init(
        getAllPaymentsUseCase: GetAllPaymentsUseCase,
        deletePaymentUseCase: DeletePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil,
        mapper: PaymentUIMapping
    ) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.deletePaymentUseCase = deletePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
        self.mapper = mapper

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
            // Convert Domain -> UI using mapper
            payments = mapper.toUI(fetchedPayments)
            logger.info("✅ Fetched \(fetchedPayments.count) payments from local storage (showLoading: \(showLoading))")

            // Reschedule notifications for all payments on first load (to restore after app updates)
            if !hasRescheduledNotifications, let notificationsUseCase = scheduleNotificationsUseCase {
                hasRescheduledNotifications = true
                Task { @MainActor in
                    notificationsUseCase.rescheduleAll(fetchedPayments)
                    logger.info("✅ Rescheduled notifications for \(fetchedPayments.count) payments")
                }
            }

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
                lastSyncedAt: payment.lastSyncedAt,
                groupId: payment.groupId
            )
            payments[index] = updatedPayment
        }

        // Perform actual update in background (no loading state to avoid flicker)
        let result = await togglePaymentStatusUseCase.execute(mapper.toDomain(payment))

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

    /// Toggle payment group status (both PEN and USD payments)
    func toggleGroupStatus(_ group: PaymentGroupUI) async {
        // Toggle all payments in the group
        if let penPayment = group.penPayment {
            await togglePaymentStatus(penPayment)
        }
        if let usdPayment = group.usdPayment {
            await togglePaymentStatus(usdPayment)
        }
    }

    /// Delete payment group (both PEN and USD payments)
    func deleteGroup(_ group: PaymentGroupUI) async {
        // Delete all payments in the group
        if let penPayment = group.penPayment {
            await deletePayment(penPayment)
        }
        if let usdPayment = group.usdPayment {
            await deletePayment(usdPayment)
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
