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
    private let eventBus: EventBus
    private let mapper: PaymentUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentHistoryViewModel")

    init(getPaymentHistoryUseCase: GetPaymentHistoryUseCase, eventBus: EventBus, mapper: PaymentUIMapping) {
        self.getPaymentHistoryUseCase = getPaymentHistoryUseCase
        self.eventBus = eventBus
        self.mapper = mapper
        // Note: Initial data fetch moved to .task in View (iOS 18 best practice)
        setupEventListeners()
    }

    private func setupEventListeners() {
        // Listen to any payment changes and refresh history
        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentCreatedEvent.self) {
                logger.debug("📬 Received PaymentCreatedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentUpdatedEvent.self) {
                logger.debug("📬 Received PaymentUpdatedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentDeletedEvent.self) {
                logger.debug("📬 Received PaymentDeletedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentStatusToggledEvent.self) {
                logger.debug("📬 Received PaymentStatusToggledEvent")
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
