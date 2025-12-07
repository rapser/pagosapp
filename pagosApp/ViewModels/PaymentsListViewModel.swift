//
//  PaymentsListViewModel.swift
//  pagosApp
//
//  ViewModel for PaymentsListView following MVVM architecture
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import OSLog

@MainActor
class PaymentsListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var payments: [Payment] = []
    @Published var selectedFilter: PaymentFilter = .currentMonth
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let modelContext: ModelContext
    private let paymentOperations: PaymentOperationsService
    private let syncService: PaymentSyncService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentsListViewModel")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var filteredPayments: [Payment] {
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

    // MARK: - Initialization (DIP: inject dependencies)

    init(
        modelContext: ModelContext,
        paymentOperations: PaymentOperationsService,
        syncService: PaymentSyncService
    ) {
        self.modelContext = modelContext
        self.paymentOperations = paymentOperations
        self.syncService = syncService
        self.isLoading = true // Start with loading state
        fetchPayments()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name("PaymentsDidSync"))
            .sink { [weak self] _ in
                self?.fetchPayments()
            }
            .store(in: &cancellables)
    }

    /// Convenience initializer with default dependencies
    convenience init(modelContext: ModelContext) {
        let repository = PaymentRepository(supabaseClient: supabaseClient, modelContext: modelContext)
        let syncService = DefaultPaymentSyncService(repository: repository)
        let notificationService = NotificationManagerAdapter()
        let calendarService = EventKitManagerAdapter()
        let paymentOperations = DefaultPaymentOperationsService(
            modelContext: modelContext,
            syncService: syncService,
            notificationService: notificationService,
            calendarService: calendarService
        )

        self.init(
            modelContext: modelContext,
            paymentOperations: paymentOperations,
            syncService: syncService
        )
    }

    // MARK: - Data Operations

    /// Fetch all payments from local database
    func fetchPayments() {
        defer {
            isLoading = false
        }
        
        do {
            let descriptor = FetchDescriptor<Payment>(sortBy: [SortDescriptor(\.dueDate, order: .forward)])
            payments = try modelContext.fetch(descriptor)
            logger.info("✅ Fetched \(self.payments.count) payments from local database")
        } catch {
            logger.error("❌ Failed to fetch payments: \(error.localizedDescription)")
            self.error = error
            ErrorHandler.shared.handle(PaymentError.saveFailed(error))
        }
    }

    /// Delete a payment (SRP: delegate to PaymentOperationsService)
    func deletePayment(_ payment: Payment) {
        isLoading = true
        defer { isLoading = false }

        Task {
            do {
                try await paymentOperations.deletePayment(payment)
                logger.info("✅ Payment deleted: \(payment.name)")
                fetchPayments()
            } catch {
                logger.error("❌ Failed to delete payment: \(error.localizedDescription)")
                ErrorHandler.shared.handle(PaymentError.deleteFailed(error))
            }
        }
    }

    /// Toggle payment status (SRP: delegate to PaymentOperationsService)
    func togglePaymentStatus(_ payment: Payment) {
        payment.isPaid.toggle()

        isLoading = true
        defer { isLoading = false }

        Task {
            do {
                try await paymentOperations.updatePayment(payment)
                logger.info("✅ Payment status updated: \(payment.name) - isPaid: \(payment.isPaid)")
                fetchPayments()
            } catch {
                logger.error("❌ Failed to update payment status: \(error.localizedDescription)")
                ErrorHandler.shared.handle(PaymentError.updateFailed(error))
                payment.isPaid.toggle() // Revert on error
            }
        }
    }

    /// Refresh data
    func refresh() {
        fetchPayments()
    }

    /// Update the model context (used when the environment context becomes available)
    func updateModelContext(_ newContext: ModelContext) {
        // Only update if the context is different
        if modelContext !== newContext {
            logger.info("Updating PaymentsListViewModel with new ModelContext")
            // Note: In a real implementation, you might want to re-initialize dependencies
            // For now, we'll just update the reference and refresh data
            // This is a simplified approach - in production you might want to recreate the entire viewModel
            fetchPayments()
        }
    }
}

// MARK: - Payment Filter Enum

enum PaymentFilter: String, CaseIterable, Identifiable {
    case currentMonth = "Próximos"
    case futureMonths = "Futuros"

    var id: String { self.rawValue }
}
