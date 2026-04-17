//
//  PaymentsListViewModel.swift
//  pagosApp
//
//  ViewModel for PaymentsListView using Clean Architecture
//  Uses Use Cases instead of direct repository/service access
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class PaymentsListViewModel: BaseViewModel {
    var payments: [PaymentUI] = [] {
        didSet { scheduleGroupedPaymentsRecompute() }
    }

    private var filterSelection: PaymentFilterUI = .currentMonth
    var selectedFilter: PaymentFilterUI {
        get { filterSelection }
        set {
            filterSelection = newValue
            scheduleGroupedPaymentsRecompute()
        }
    }

    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let deletePaymentUseCase: DeletePaymentUseCase
    private let togglePaymentStatusUseCase: TogglePaymentStatusUseCase
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let mapper: PaymentUIMapping
    private let searchService: PaymentSearchService

    // Track if we've already rescheduled notifications on first load
    private var hasRescheduledNotifications = false
    private var recomputeTask: Task<Void, Never>?
    private let recomputeDebounceNanoseconds: UInt64 = 150_000_000

    // MARK: - Computed Properties

    var filteredPayments: [PaymentUI] {
        let filter = PaymentSearchService.PaymentFilter.from(selectedFilter)
        return searchService.filter(payments, by: filter)
    }

    /// Cached grouped payments — updated only when payments or filter change.
    private(set) var groupedPayments: [PaymentListItemUI] = []

    private func scheduleGroupedPaymentsRecompute() {
        recomputeTask?.cancel()
        recomputeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: self?.recomputeDebounceNanoseconds ?? 0)
            guard !Task.isCancelled else { return }
            self?.recomputeGroupedPayments()
        }
    }

    private func recomputeGroupedPayments() {
        var items: [PaymentListItemUI] = []
        var processedIds: Set<UUID> = []

        let paymentsWithGroupId = filteredPayments.filter { $0.groupId != nil }
        let paymentsByGroupId = Dictionary(grouping: paymentsWithGroupId) { $0.groupId! }

        for (groupId, grouped) in paymentsByGroupId {
            guard grouped.first?.category == .tarjetaCredito else {
                for payment in grouped {
                    items.append(.individual(payment))
                    processedIds.insert(payment.id)
                }
                continue
            }

            let penPayment = grouped.first { $0.currency == .pen }
            let usdPayment = grouped.first { $0.currency == .usd }

            if let group = PaymentGroupUI.from(penPayment: penPayment, usdPayment: usdPayment, groupId: groupId) {
                items.append(.group(group))
                if let pen = penPayment { processedIds.insert(pen.id) }
                if let usd = usdPayment { processedIds.insert(usd.id) }
            }
        }

        for payment in filteredPayments where !processedIds.contains(payment.id) {
            items.append(.individual(payment))
        }

        items.sort { $0.dueDate < $1.dueDate }
        groupedPayments = items
    }

    // MARK: - Initialization

    init(
        getAllPaymentsUseCase: GetAllPaymentsUseCase,
        deletePaymentUseCase: DeletePaymentUseCase,
        togglePaymentStatusUseCase: TogglePaymentStatusUseCase,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil,
        eventBus: EventBus,
        mapper: PaymentUIMapping,
        searchService: PaymentSearchService = PaymentSearchService()
    ) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.deletePaymentUseCase = deletePaymentUseCase
        self.togglePaymentStatusUseCase = togglePaymentStatusUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
        self.eventBus = eventBus
        self.mapper = mapper
        self.searchService = searchService
        super.init(category: "PaymentsListViewModel")

        setupEventListeners()
    }

    private func setupEventListeners() {
        // Listen to payment events and refresh UI
        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentCreatedEvent.self) ?? AsyncStream.never {
                await self?.fetchPayments(showLoading: false)
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentUpdatedEvent.self) ?? AsyncStream.never {
                await self?.fetchPayments(showLoading: false)
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentDeletedEvent.self) ?? AsyncStream.never {
                await self?.fetchPayments(showLoading: false)
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentStatusToggledEvent.self) ?? AsyncStream.never {
                await self?.fetchPayments(showLoading: false)
            }
        }
    }

    // MARK: - Data Operations

    /// Fetch all payments from repository (reads from local SwiftData - fast)
    /// - Parameter showLoading: Whether to show loading indicator (default: true). Set to false for silent background refreshes.
    func fetchPayments(showLoading: Bool = true) async {
        if !showLoading {
            // For silent refreshes, don't use loading state management
            let result = await getAllPaymentsUseCase.execute()
            switch result {
            case .success(let fetchedPayments):
                payments = mapper.toUI(fetchedPayments)
                logDebug("Fetched \(fetchedPayments.count) payments (silent refresh)")

                ListNotificationBootstrap.runPaymentRescheduleIfNeeded(
                    hasAlreadyRescheduled: &hasRescheduledNotifications,
                    payments: fetchedPayments,
                    useCase: scheduleNotificationsUseCase
                )
            case .failure(let error):
                logError(error)
            }
            return
        }
        
        // For normal fetches, use loading state management
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getAllPaymentsUseCase.execute()
                switch result {
                case .success(let fetchedPayments):
                    self.payments = self.mapper.toUI(fetchedPayments)
                    self.logDebug("Fetched \(fetchedPayments.count) payments")
                    
                    ListNotificationBootstrap.runPaymentRescheduleIfNeeded(
                        hasAlreadyRescheduled: &self.hasRescheduledNotifications,
                        payments: fetchedPayments,
                        useCase: self.scheduleNotificationsUseCase
                    )
                    
                    return fetchedPayments
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
            },
            onError: { error in
                if let paymentError = error as? PaymentError {
                    self.setError(PaymentErrorMessageMapper.message(for: paymentError))
                }
            }
        )
    }

    /// Delete a payment with optimistic UI update
    func deletePayment(_ payment: PaymentUI) async {
        // Optimistic update - remove from UI immediately
        payments.removeAll { $0.id == payment.id }

        // Perform actual delete in background
        let result = await deletePaymentUseCase.execute(paymentId: payment.id)

        switch result {
        case .success:
            break

        case .failure(let error):
            // Revert optimistic delete on failure - re-add payment
            payments.append(payment)
            setError(PaymentErrorMessageMapper.message(for: error))
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
        case .success:
            break

        case .failure(let error):
            // Revert optimistic update on failure
            if let index = payments.firstIndex(where: { $0.id == payment.id }) {
                payments[index] = payment
            }
            setError(PaymentErrorMessageMapper.message(for: error))
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
}
