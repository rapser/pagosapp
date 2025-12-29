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
                            if vm.isLoading {
                                ProgressView("Cargando estadísticas...")
                                    .padding(.top, 100)
                            } else if vm.categoryStats.isEmpty && vm.monthlyStats.isEmpty {
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
                                        totalSpending: vm.totalSpending
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

// MARK: - Subviews

private struct CurrencyTabSelector: View {
    @Binding var selectedCurrency: Currency
    let totalSpending: Double
    
    // TODO: Get from ViewModel (check if there are payments in each currency)
    private var hasPENPayments: Bool { true }
    private var hasUSDPayments: Bool { true }
    
    var body: some View {
        HStack(spacing: 0) {
            // Tab Soles
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedCurrency = .pen
                }
            } label: {
                CurrencyTab(
                    title: "Soles",
                    symbol: "S/",
                    totalSpending: selectedCurrency == .pen ? totalSpending : nil,
                    isSelected: selectedCurrency == .pen
                )
            }
            .disabled(!hasPENPayments)
            .opacity(hasPENPayments ? 1.0 : 0.5)
            
            // Tab Dólares
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedCurrency = .usd
                }
            } label: {
                CurrencyTab(
                    title: "Dólares",
                    symbol: "$",
                    totalSpending: selectedCurrency == .usd ? totalSpending : nil,
                    isSelected: selectedCurrency == .usd
                )
            }
            .disabled(!hasUSDPayments)
            .opacity(hasUSDPayments ? 1.0 : 0.5)
        }
        .background(Color("AppBackground"))
        .cornerRadius(12)
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 1)
                .padding(.horizontal)
        )
    }
}

private struct CurrencyTab: View {
    let title: String
    let symbol: String
    let totalSpending: Double?
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            if let total = totalSpending {
                Text("\(total, format: .number.precision(.fractionLength(2)))")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? Color("AppPrimary").opacity(0.1) : Color.clear)
        .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppTextSecondary"))
    }
}

private struct EmptyStateView: View {
    let currency: Currency
    let filter: StatsFilter
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(Color("AppTextSecondary"))
            Text("No hay pagos en \(currency == .pen ? "Soles" : "Dólares")")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
            Text("para \"\(filter.rawValue)\"")
                .font(.subheadline)
                .foregroundColor(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct CategoryPieChart: View {
    let categoryData: [CategorySpending]
    let totalSpending: Double
    let selectedCurrency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gastos por Categoría")
                    .font(.title3).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("\(selectedCurrency.symbol)\(totalSpending, format: .number.precision(.fractionLength(2)))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppPrimary"))
            }
            .padding(.horizontal)
            
            Chart(categoryData) { data in
                SectorMark(
                    angle: .value("Monto", data.totalAmount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Categoría", data.category.rawValue))
            }
            .frame(height: 280)
            .chartLegend(position: .bottom, alignment: .center)
            .padding(.horizontal)

            // Lista de categorías
            VStack(spacing: 0) {
                ForEach(categoryData) { data in
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text(data.category.rawValue)
                            .foregroundColor(Color("AppTextPrimary"))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(data.currency.symbol)\(data.totalAmount, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AppTextPrimary"))
                            Text("\(Int((data.totalAmount / totalSpending) * 100))%")
                                .font(.caption2)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if data.id != categoryData.last?.id {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
            .background(Color("AppBackground"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

private struct MonthlyBarChart: View {
    let monthlyData: [MonthlySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimos 6 Meses")
                .font(.title3).bold()
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.horizontal)
            
            Chart(monthlyData) { data in
                BarMark(
                    x: .value("Mes", data.month, unit: .month),
                    y: .value("Total", data.totalAmount)
                )
                .foregroundStyle(Color("AppPrimary").gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: monthlyData.count)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
            .padding(.horizontal)
        }
    }
}
