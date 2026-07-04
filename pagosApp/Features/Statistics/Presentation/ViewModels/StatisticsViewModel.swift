//
//  StatisticsViewModel.swift
//  pagosApp
//
//  ViewModel for Statistics using Clean Architecture
//  Uses Use Cases instead of direct SwiftData queries
//

import Foundation

@MainActor
@Observable
final class StatisticsViewModel: BaseViewModel {
    // MARK: - Observable Properties (UI State)

    var categoryStats: [CategoryStats] = []
    var monthlyStats: [MonthlyStats] = []
    /// Total para Soles (independiente de la moneda seleccionada)
    var penTotalSpending: Double = 0
    /// Total para Dólares (independiente de la moneda seleccionada)
    var usdTotalSpending: Double = 0
    var selectedFilter: StatsFilter = .all
    var selectedCurrency: Currency = .pen
    var hasPENPayments: Bool = false
    var hasUSDPayments: Bool = false

    /// Se calcula una sola vez al cargar; las monedas disponibles no cambian con el filtro.
    private var hasCheckedCurrencies = false

    // MARK: - Dependencies (Use Cases)

    private let calculateCategoryStatsUseCase: CalculateCategoryStatsUseCase
    private let calculateMonthlyStatsUseCase: CalculateMonthlyStatsUseCase
    private let getTotalSpendingUseCase: GetTotalSpendingUseCase
    private let checkPaymentsByCurrencyUseCase: CheckPaymentsByCurrencyUseCase

    init(
        calculateCategoryStatsUseCase: CalculateCategoryStatsUseCase,
        calculateMonthlyStatsUseCase: CalculateMonthlyStatsUseCase,
        getTotalSpendingUseCase: GetTotalSpendingUseCase,
        checkPaymentsByCurrencyUseCase: CheckPaymentsByCurrencyUseCase
    ) {
        self.calculateCategoryStatsUseCase = calculateCategoryStatsUseCase
        self.calculateMonthlyStatsUseCase = calculateMonthlyStatsUseCase
        self.getTotalSpendingUseCase = getTotalSpendingUseCase
        self.checkPaymentsByCurrencyUseCase = checkPaymentsByCurrencyUseCase
        super.init(category: "StatisticsViewModel")
    }

    // MARK: - Computed Properties

    /// Total para la moneda actualmente seleccionada
    var totalSpending: Double {
        selectedCurrency == .pen ? penTotalSpending : usdTotalSpending
    }

    // MARK: - Load Operations

    /// Carga completa: categorías, mensual, totales de ambas monedas y disponibilidad de monedas.
    func loadStatistics() async {
        async let categoryLoad: Void = loadCategoryStats()
        async let monthlyLoad: Void = loadMonthlyStats()
        async let totalsLoad: Void = loadBothTotals()

        if hasCheckedCurrencies {
            _ = await (categoryLoad, monthlyLoad, totalsLoad)
            return
        }

        async let currencyLoad: Void = loadAvailableCurrencies()
        _ = await (categoryLoad, monthlyLoad, totalsLoad, currencyLoad)
        hasCheckedCurrencies = true
    }

    /// Carga los totales de PEN y USD para el filtro activo (aprovecha el cache del repositorio).
    func loadBothTotals() async {
        async let penResult = getTotalSpendingUseCase.execute(filter: selectedFilter, currency: .pen)
        async let usdResult = getTotalSpendingUseCase.execute(filter: selectedFilter, currency: .usd)
        if case .success(let t) = await penResult { penTotalSpending = t }
        if case .success(let t) = await usdResult { usdTotalSpending = t }
    }

    /// Verifica qué monedas tienen pagos. Solo se llama una vez por ciclo de vida del ViewModel.
    func loadAvailableCurrencies() async {
        async let penPayments = checkPaymentsByCurrencyUseCase.execute(currency: .pen)
        async let usdPayments = checkPaymentsByCurrencyUseCase.execute(currency: .usd)
        hasPENPayments = await penPayments
        hasUSDPayments = await usdPayments
    }

    func loadCategoryStats() async {
        let result = await calculateCategoryStatsUseCase.execute(
            filter: selectedFilter,
            currency: selectedCurrency
        )
        switch result {
        case .success(let stats):
            categoryStats = stats
        case .failure(let error):
            logError(error)
            setError(L10n.Statistics.errorCategory)
        }
    }

    func loadMonthlyStats() async {
        let result = await calculateMonthlyStatsUseCase.execute(
            monthCount: 6,
            currency: selectedCurrency
        )
        switch result {
        case .success(let stats):
            monthlyStats = stats
        case .failure(let error):
            logError(error)
            setError(L10n.Statistics.errorMonthly)
        }
    }

    // MARK: - User Actions

    /// Cambia el filtro de período y recarga stats + ambos totales. Las monedas disponibles no cambian.
    func updateFilter(_ newFilter: StatsFilter) async {
        selectedFilter = newFilter
        async let categoryLoad: Void = loadCategoryStats()
        async let monthlyLoad: Void = loadMonthlyStats()
        async let totalsLoad: Void = loadBothTotals()
        _ = await (categoryLoad, monthlyLoad, totalsLoad)
    }

    /// Cambia la moneda activa. Los totales ya están cargados para ambas monedas, solo recarga las charts.
    func updateCurrency(_ newCurrency: Currency) async {
        selectedCurrency = newCurrency
        categoryStats = []
        monthlyStats = []
        async let categoryLoad: Void = loadCategoryStats()
        async let monthlyLoad: Void = loadMonthlyStats()
        _ = await (categoryLoad, monthlyLoad)
    }

    func refresh() async {
        hasCheckedCurrencies = false
        await loadStatistics()
    }

    // MARK: - Presentation Helpers

    var hasValidChartData: Bool {
        !categoryStats.isEmpty && totalSpending > 0 && totalSpending.isFinite
    }

    var categorySpendingData: [CategorySpendingUI] {
        categoryStats.map { CategorySpendingUI(from: $0) }
    }

    var monthlySpendingData: [MonthlySpendingUI] {
        monthlyStats.map { MonthlySpendingUI(from: $0) }
    }
}
