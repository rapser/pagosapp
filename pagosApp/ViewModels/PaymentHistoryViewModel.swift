//
//  PaymentHistoryViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftUI
import SwiftData
import Observation
import OSLog

@MainActor
@Observable
final class PaymentHistoryViewModel {
    var payments: [Payment] = []
    var selectedFilter: PaymentHistoryFilter = .completed
    var isLoading = false
    var error: Error?

    // MARK: - Dependencies (DIP: depend on abstractions)

    private let modelContext: ModelContext
    private let errorHandler: ErrorHandler
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentHistoryViewModel")

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

    init(modelContext: ModelContext, errorHandler: ErrorHandler) {
        self.modelContext = modelContext
        self.errorHandler = errorHandler
        fetchPayments()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        Task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("PaymentsDidSync")) {
                fetchPayments()
            }
        }
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
            errorHandler.handle(PaymentError.saveFailed(error))
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