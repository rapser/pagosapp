//
//  PaymentHistoryViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import OSLog

@MainActor
class PaymentHistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var payments: [Payment] = []
    @Published var selectedFilter: PaymentHistoryFilter = .completed
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentHistoryViewModel")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var filteredPayments: [Payment] {
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

    // MARK: - Initialization (DIP: inject dependencies)

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

    // MARK: - Data Operations

    /// Fetch all payments from local database
    func fetchPayments() {
        do {
            let descriptor = FetchDescriptor<Payment>(sortBy: [SortDescriptor(\.dueDate, order: .reverse)]) // Most recent first
            payments = try modelContext.fetch(descriptor)
            logger.info("✅ Fetched \(self.payments.count) payments for history")
        } catch {
            logger.error("❌ Failed to fetch payments: \(error.localizedDescription)")
            self.error = error
            ErrorHandler.shared.handle(PaymentError.saveFailed(error))
        }
    }

    /// Refresh data
    func refresh() {
        fetchPayments()
    }
}

// MARK: - Payment History Filter Enum

enum PaymentHistoryFilter: String, CaseIterable, Identifiable {
    case completed = "Completados"
    case overdue = "Vencidos"
    case all = "Todos"

    var id: String { self.rawValue }
}