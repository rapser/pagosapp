//
//  StatisticsUseCaseTests.swift
//  pagosAppTests
//
//  Unit tests for Statistics use cases.
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - CalculateCategoryStatsUseCase

@Suite("CalculateCategoryStatsUseCase")
@MainActor
struct CalculateCategoryStatsUseCaseTests {
    let repo = MockStatisticsRepository()
    let sut: CalculateCategoryStatsUseCase

    init() {
        sut = CalculateCategoryStatsUseCase(statisticsRepository: repo, log: NullLog())
    }

    @Test func multipleCategories_groupedAndSortedDescending() async {
        repo.filteredPayments = [
            Payment.make(amount: 200, category: .vivienda),
            Payment.make(amount: 50, category: .servicios),
            Payment.make(amount: 100, category: .vivienda),
            Payment.make(amount: 30, category: .servicios),
        ]

        let result = await sut.execute(filter: .month, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.count == 2)
        #expect(stats[0].category == .vivienda)
        #expect(stats[0].totalAmount == 300)
        #expect(stats[1].category == .servicios)
        #expect(stats[1].totalAmount == 80)
    }

    @Test func singleCategory_returnsTotalAndCount() async {
        repo.filteredPayments = [
            Payment.make(amount: 100, category: .seguro),
            Payment.make(amount: 50, category: .seguro),
        ]

        let result = await sut.execute(filter: .year, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.count == 1)
        #expect(stats[0].totalAmount == 150)
        #expect(stats[0].paymentCount == 2)
        #expect(stats[0].currency == .pen)
    }

    @Test func emptyPayments_returnsEmptyArray() async {
        repo.filteredPayments = []

        let result = await sut.execute(filter: .all, currency: .usd)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.isEmpty)
    }

    @Test func repositoryFailure_propagatesError() async {
        repo.shouldFail = true

        let result = await sut.execute(filter: .month, currency: .pen)

        guard case .failure = result else {
            Issue.record("Expected .failure")
            return
        }
    }

    @Test func sortedDescendingByTotal() async {
        repo.filteredPayments = [
            Payment.make(amount: 10, category: .educacion),
            Payment.make(amount: 500, category: .tarjetaCredito),
            Payment.make(amount: 100, category: .prestamo),
        ]

        let result = await sut.execute(filter: .all, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        let totals = stats.map { $0.totalAmount }
        #expect(totals == totals.sorted(by: >))
    }
}

// MARK: - CalculateMonthlyStatsUseCase

@Suite("CalculateMonthlyStatsUseCase")
@MainActor
struct CalculateMonthlyStatsUseCaseTests {
    let repo = MockStatisticsRepository()
    let sut: CalculateMonthlyStatsUseCase

    init() {
        sut = CalculateMonthlyStatsUseCase(statisticsRepository: repo, log: NullLog())
    }

    @Test func returnsExactMonthCount() async {
        repo.monthlyPayments = []

        let result = await sut.execute(monthCount: 6, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.count == 6)
    }

    @Test func customMonthCount_honored() async {
        repo.monthlyPayments = []

        let result = await sut.execute(monthCount: 3, currency: .usd)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.count == 3)
    }

    @Test func sortedAscendingByMonth() async {
        repo.monthlyPayments = []

        let result = await sut.execute(monthCount: 4, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        let months = stats.map { $0.month }
        #expect(months == months.sorted())
    }

    @Test func paymentsInPreviousMonth_summedCorrectly() async {
        let cal = Calendar.current
        let now = Date()
        guard let prevMonth = cal.date(byAdding: .month, value: -1, to: now) else { return }

        repo.monthlyPayments = [
            Payment.make(amount: 100, dueDate: prevMonth),
            Payment.make(amount: 50, dueDate: prevMonth),
        ]

        let result = await sut.execute(monthCount: 6, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        let prevMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: prevMonth))!
        let prevMonthStat = stats.first { $0.month == prevMonthStart }
        #expect(prevMonthStat?.totalAmount == 150)
        #expect(prevMonthStat?.paymentCount == 2)
    }

    @Test func emptyPayments_allMonthsHaveZeroTotal() async {
        repo.monthlyPayments = []

        let result = await sut.execute(monthCount: 3, currency: .pen)

        guard case .success(let stats) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(stats.allSatisfy { $0.totalAmount == 0 })
    }

    @Test func repositoryFailure_propagatesError() async {
        repo.shouldFail = true

        let result = await sut.execute(monthCount: 6, currency: .pen)

        guard case .failure = result else {
            Issue.record("Expected .failure")
            return
        }
    }
}

// MARK: - GetTotalSpendingUseCase

@Suite("GetTotalSpendingUseCase")
@MainActor
struct GetTotalSpendingUseCaseTests {
    let repo = MockStatisticsRepository()
    let sut: GetTotalSpendingUseCase

    init() {
        sut = GetTotalSpendingUseCase(statisticsRepository: repo, log: NullLog())
    }

    @Test func sumsAllAmounts() async {
        repo.filteredPayments = [
            Payment.make(amount: 100),
            Payment.make(amount: 50),
            Payment.make(amount: 25),
        ]

        let result = await sut.execute(filter: .month, currency: .pen)

        guard case .success(let total) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(total == 175.0)
    }

    @Test func emptyPayments_returnsZero() async {
        repo.filteredPayments = []

        let result = await sut.execute(filter: .all, currency: .usd)

        guard case .success(let total) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(total == 0.0)
    }

    @Test func repositoryFailure_propagatesError() async {
        repo.shouldFail = true

        let result = await sut.execute(filter: .month, currency: .pen)

        guard case .failure = result else {
            Issue.record("Expected .failure")
            return
        }
    }

    @Test func singlePayment_returnsThatAmount() async {
        repo.filteredPayments = [Payment.make(amount: 99.99)]

        let result = await sut.execute(filter: .year, currency: .pen)

        guard case .success(let total) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(abs(total - 99.99) < 0.001)
    }
}

// MARK: - CheckPaymentsByCurrencyUseCase

@Suite("CheckPaymentsByCurrencyUseCase")
@MainActor
struct CheckPaymentsByCurrencyUseCaseTests {
    let repo = MockPaymentRepository()
    let sut: CheckPaymentsByCurrencyUseCase

    init() {
        sut = CheckPaymentsByCurrencyUseCase(paymentRepository: repo)
    }

    @Test func hasPENPayments_returnsTrueForPEN() async {
        repo.payments = [Payment.make(currency: .pen)]

        let hasPEN = await sut.execute(currency: .pen)

        #expect(hasPEN == true)
    }

    @Test func noUSDPayments_returnsFalseForUSD() async {
        repo.payments = [Payment.make(currency: .pen)]

        let hasUSD = await sut.execute(currency: .usd)

        #expect(hasUSD == false)
    }

    @Test func emptyPayments_returnsFalseForAny() async {
        repo.payments = []

        let hasPEN = await sut.execute(currency: .pen)
        let hasUSD = await sut.execute(currency: .usd)

        #expect(hasPEN == false)
        #expect(hasUSD == false)
    }

    @Test func getAvailableCurrencies_returnsBothWhenBothPresent() async {
        repo.payments = [Payment.make(currency: .pen), Payment.make(currency: .usd)]

        let currencies = await sut.getAvailableCurrencies()

        #expect(currencies.contains(.pen))
        #expect(currencies.contains(.usd))
        #expect(currencies.count == 2)
    }

    @Test func getAvailableCurrencies_returnsOnlyPresentCurrencies() async {
        repo.payments = [Payment.make(currency: .pen), Payment.make(currency: .pen)]

        let currencies = await sut.getAvailableCurrencies()

        #expect(currencies == [.pen])
    }

    @Test func getAvailableCurrencies_emptyPayments_returnsEmptySet() async {
        repo.payments = []

        let currencies = await sut.getAvailableCurrencies()

        #expect(currencies.isEmpty)
    }
}
