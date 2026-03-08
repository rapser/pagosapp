//
//  StatisticsView.swift
//  pagosApp
//
//  Clean Architecture - Uses StatisticsViewModel with Use Cases
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var viewModel: StatisticsViewModel

    init(viewModel: StatisticsViewModel) {
        // Initialize ViewModel immediately (no loader needed - reads from local SwiftData)
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if vm.categoryStats.isEmpty && vm.monthlyStats.isEmpty {
                        ContentUnavailableView(
                            L10n.Statistics.noDataTitle,
                            systemImage: "chart.pie",
                            description: Text(L10n.Statistics.noDataDescription)
                        )
                        .foregroundColor(Color("AppTextSecondary"))
                        .padding(.top, 100)
                    } else {
                        // Header con filtro de tiempo
                        VStack(spacing: 16) {
                            Picker(L10n.Statistics.periodPicker, selection: $vm.selectedFilter) {
                                ForEach(StatsFilter.allCases) { filter in
                                    Text(L10n.Statistics.periodDisplayName(filter)).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top)
                            .onChange(of: vm.selectedFilter) { _, newValue in
                                Task {
                                    await vm.updateFilter(newValue)
                                }
                            }

                            // Selector de moneda con diseño de tabs
                            CurrencyTabSelector(
                                selectedCurrency: $vm.selectedCurrency,
                                totalSpending: vm.totalSpending,
                                hasPENPayments: vm.hasPENPayments,
                                hasUSDPayments: vm.hasUSDPayments
                            )
                            .onChange(of: vm.selectedCurrency) { _, newValue in
                                Task {
                                    await vm.updateCurrency(newValue)
                                }
                            }
                        }
                        .padding(.bottom)

                        if !vm.hasValidChartData {
                            EmptyStateView(
                                currency: vm.selectedCurrency,
                                filter: vm.selectedFilter
                            )
                        } else {
                            // Gráfico de torta - Gastos por Categoría
                            CategoryPieChart(
                                categoryData: vm.categorySpendingData,
                                totalSpending: vm.totalSpending,
                                selectedCurrency: vm.selectedCurrency,
                                shouldShowChart: vm.hasValidChartData
                            )
                            .padding(.vertical)

                            // Gráfico de barras - Últimos 6 Meses
                            MonthlyBarChart(
                                monthlyData: vm.monthlySpendingData
                            )
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Statistics.title)
        }
        .task {
            // Load statistics from SwiftData (fast, no loader needed)
            await viewModel.loadStatistics()
        }
    }
}
