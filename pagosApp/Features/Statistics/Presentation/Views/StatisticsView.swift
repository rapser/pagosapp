//
//  StatisticsView.swift
//  pagosApp
//
//  Clean Architecture - Uses StatisticsViewModel with Use Cases
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: StatisticsViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            if vm.categoryStats.isEmpty && vm.monthlyStats.isEmpty {
                                ContentUnavailableView(
                                    "Sin Datos",
                                    systemImage: "chart.pie",
                                    description: Text("Añade algunos pagos para ver las estadísticas.")
                                )
                                .foregroundColor(Color("AppTextSecondary"))
                                .padding(.top, 100)
                            } else {
                                // Header con filtro de tiempo
                                VStack(spacing: 16) {
                                    Picker("Período", selection: $vm.selectedFilter) {
                                        ForEach(StatsFilter.allCases) { filter in
                                            Text(filter.rawValue).tag(filter)
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
                                
                                if vm.categorySpendingData.isEmpty {
                                    EmptyStateView(
                                        currency: vm.selectedCurrency,
                                        filter: vm.selectedFilter
                                    )
                                } else {
                                    // Gráfico de torta - Gastos por Categoría
                                    CategoryPieChart(
                                        categoryData: vm.categorySpendingData,
                                        totalSpending: vm.totalSpending,
                                        selectedCurrency: vm.selectedCurrency
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
                } else {
                    ProgressView("Inicializando...")
                }
            }
            .navigationTitle("Estadísticas")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.statisticsDependencyContainer.makeStatisticsViewModel()
                Task {
                    await viewModel?.loadStatistics()
                }
            }
        }
    }
}
