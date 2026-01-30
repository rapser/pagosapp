import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
final class PaymentHistoryViewModel {
    var filteredPayments: [PaymentUI] = []
    var selectedFilter: PaymentHistoryFilter = .completed
    var isLoading = false
    var errorMessage: String?

    private let getPaymentHistoryUseCase: GetPaymentHistoryUseCase
    private let mapper: PaymentUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentHistoryViewModel")

    init(getPaymentHistoryUseCase: GetPaymentHistoryUseCase, mapper: PaymentUIMapping) {
        self.getPaymentHistoryUseCase = getPaymentHistoryUseCase
        self.mapper = mapper
        // Note: Initial data fetch moved to .task in View (iOS 18 best practice)
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

        let result = await getPaymentHistoryUseCase.execute(filter: selectedFilter)

        switch result {
        case .success(let payments):
            // Convert Domain -> UI
            filteredPayments = mapper.toUI(payments)
            errorMessage = nil
            logger.info("✅ Fetched \(self.filteredPayments.count) payments for history (filter: \(self.selectedFilter.rawValue))")
        case .failure(let error):
            logger.error("❌ Failed to fetch payment history: \(error.errorCode)")
            errorMessage = "Error al cargar el historial de pagos"
        }
    }

    func updateFilter(_ newFilter: PaymentHistoryFilter) async {
        selectedFilter = newFilter
        await fetchPayments()
    }

    func refresh() async {
        await fetchPayments()
    }
}
