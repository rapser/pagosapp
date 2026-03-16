import Foundation

@MainActor
@Observable
final class PaymentHistoryViewModel: BaseViewModel {
    var allPayments: [PaymentUI] = []
    var selectedFilter: PaymentHistoryFilter = .completed
    
    private(set) var paginationState = PaginationState<PaymentUI>()

    private let getPaymentHistoryUseCase: GetPaymentHistoryUseCase
    private let eventBus: EventBus
    private let mapper: PaymentUIMapping
    private let searchService: PaymentSearchService

    // MARK: - Computed Properties
    
    var filteredPayments: [PaymentUI] {
        let filter = PaymentSearchService.PaymentFilter.from(selectedFilter)
        if case .compound(let filters) = filter, filters.isEmpty {
            return paginationState.items
        }
        return searchService.filter(paginationState.items, by: filter)
    }

    init(
        getPaymentHistoryUseCase: GetPaymentHistoryUseCase, 
        eventBus: EventBus, 
        mapper: PaymentUIMapping,
        searchService: PaymentSearchService = PaymentSearchService()
    ) {
        self.getPaymentHistoryUseCase = getPaymentHistoryUseCase
        self.eventBus = eventBus
        self.mapper = mapper
        self.searchService = searchService
        super.init(category: "PaymentHistoryViewModel")
        setupEventListeners()
    }

    private func setupEventListeners() {
        // Listen to any payment changes and refresh history
        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentCreatedEvent.self) {
                logDebug("Received PaymentCreatedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentUpdatedEvent.self) {
                logDebug("Received PaymentUpdatedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentDeletedEvent.self) {
                logDebug("Received PaymentDeletedEvent")
                await fetchPayments()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentStatusToggledEvent.self) {
                logDebug("Received PaymentStatusToggledEvent")
                await fetchPayments()
            }
        }
    }

    func fetchPayments() async {
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getPaymentHistoryUseCase.execute(filter: self.selectedFilter)
                
                switch result {
                case .success(let payments):
                    let uiPayments = self.mapper.toUI(payments)
                    
                    // Apply pagination to in-memory data
                    let paginatedResult = PaginationHelper.paginate(
                        uiPayments, 
                        page: 1, 
                        pageSize: PaginationConfig.default.pageSize
                    )
                    
                    self.paginationState.update(with: paginatedResult)
                    self.allPayments = uiPayments
                    self.logDebug("Fetched \(uiPayments.count) payments for history (filter: \(self.selectedFilter.rawValue))")
                    return uiPayments
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
            },
            onError: { _ in
                self.setError(L10n.History.errorLoad)
            }
        )
    }
    
    /// Load more items for infinite scroll
    func loadMoreIfNeeded() async {
        guard paginationState.canLoadMore else { return }
        
        paginationState.isLoadingMore = true
        defer { paginationState.isLoadingMore = false }
        
        let nextPage = paginationState.currentPage + 1
        let nextPageResult = PaginationHelper.paginate(
            allPayments,
            page: nextPage,
            pageSize: paginationState.config.pageSize
        )
        
        paginationState.update(with: nextPageResult)
        logDebug("Loaded page \(nextPage) of history (\(paginationState.items.count) total visible)")
    }

    func updateFilter(_ newFilter: PaymentHistoryFilter) async {
        selectedFilter = newFilter
        paginationState.reset()
        await fetchPayments()
    }

    func refresh() async {
        await fetchPayments()
    }
}
