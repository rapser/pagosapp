import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
final class PaymentHistoryViewModel {
    var payments: [PaymentEntity] = []
    var selectedFilter: PaymentHistoryFilter = .completed
    var isLoading = false
    var errorMessage: String?

    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentHistoryViewModel")

    var filteredPayments: [PaymentEntity] {
        let now = Date()

        switch selectedFilter {
        case .completed:
            return payments.filter { $0.isPaid }
        case .overdue:
            return payments.filter { !$0.isPaid && $0.dueDate < now }
        case .all:
            return payments.filter { $0.isPaid || $0.dueDate < now }
        }
    }

    init(getAllPaymentsUseCase: GetAllPaymentsUseCase) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        Task {
            await fetchPayments()
        }
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        Task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("PaymentsDidSync")) {
                await fetchPayments()
            }
        }
    }

    func fetchPayments() async {
        isLoading = true
        defer { isLoading = false }

        let result = await getAllPaymentsUseCase.execute()

        switch result {
        case .success(let fetchedPayments):
            payments = fetchedPayments.sorted { $0.dueDate > $1.dueDate }
            errorMessage = nil
            logger.info("✅ Fetched \(self.payments.count) payments for history")
        case .failure(let error):
            logger.error("❌ Failed to fetch payments: \(error.errorCode)")
            errorMessage = "Error al cargar el historial de pagos"
        }
    }

    func refresh() async {
        await fetchPayments()
    }
}
