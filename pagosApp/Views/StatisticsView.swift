import SwiftUI
import Charts
import SwiftData

/// Estructura para almacenar los datos agregados para el gráfico.
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: PaymentCategory
    let totalAmount: Double
    let currency: Currency
}

/// Estructura para almacenar los datos de gastos mensuales para el gráfico de barras.
struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let totalAmount: Double
    let currency: Currency
}

/// Enum para las opciones de filtrado en la vista de estadísticas.
enum StatsFilter: String, CaseIterable, Identifiable {
    case month = "Este Mes"
    case year = "Este Año"
    case all = "Todos"
    
    var id: Self { self }
}

struct StatisticsView: View {
    // Obtenemos todos los pagos de SwiftData.
    @Query(sort: \Payment.dueDate, order: .reverse) private var payments: [Payment]
    
    // Estado para controlar el filtro seleccionado.
    @State private var selectedFilter: StatsFilter = .all
    @State private var selectedCurrency: Currency = .pen
    
    /// Filtra los pagos según la selección del usuario (mes, año o todos).
    private var filteredPayments: [Payment] {
        let calendar = Calendar.current
        let now = Date()
        
        let timeFiltered: [Payment]
        switch selectedFilter {
        case .month:
            timeFiltered = payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
        case .year:
            timeFiltered = payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .year) }
        case .all:
            timeFiltered = payments
        }
        
        // Filtrar por moneda seleccionada
        return timeFiltered.filter { $0.currency == selectedCurrency }
    }
    
    /// Verifica si hay pagos en cada moneda
    private var hasPENPayments: Bool {
        payments.contains(where: { $0.currency == .pen })
    }
    
    private var hasUSDPayments: Bool {
        payments.contains(where: { $0.currency == .usd })
    }

    // Propiedad computada que procesa los pagos para el gráfico.
    private var categoryData: [CategorySpending] {
        let spendingByCategory = Dictionary(grouping: filteredPayments, by: { $0.category })
            .mapValues { payments in
                // Sumamos los montos de todos los pagos en esa categoría.
                payments.reduce(0) { $0 + $1.amount }
            }

        // Convertimos el diccionario a un array de nuestro struct y lo ordenamos.
        return spendingByCategory.map { (category, total) in
            CategorySpending(category: category, totalAmount: total, currency: selectedCurrency)
        }.sorted { $0.totalAmount > $1.totalAmount }
    }
    
    // Total de gastos para la moneda seleccionada
    private var totalSpending: Double {
        filteredPayments.reduce(0) { $0 + $1.amount }
    }
    
    /// Propiedad computada que procesa los pagos para el gráfico de barras de los últimos 6 meses.
    private var monthlySpendingData: [MonthlySpending] {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the start of the current month
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return [] }

        // Calculate the end of the previous month (upper bound for filtering)
        guard let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else { return [] }

        // Calculate the start of the 6-month period (6 months before the end of the previous month)
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -5, to: calendar.startOfDay(for: endOfPreviousMonth)),
              let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: sixMonthsAgo)) else {
            return []
        }

        // Filter relevant payments within the 6-month period, up to the end of the previous month
        // AND filter by selected currency
        let relevantPayments = payments.filter {
            let paymentStartOfDay = calendar.startOfDay(for: $0.dueDate)
            let isRelevant = paymentStartOfDay >= startOfPeriod && paymentStartOfDay <= endOfPreviousMonth
            return isRelevant && $0.currency == selectedCurrency
        }

        // Group payments by the start of their month
        let spendingByMonth = Dictionary(grouping: relevantPayments) { payment in
            calendar.date(from: calendar.dateComponents([.year, .month], from: payment.dueDate)) ?? payment.dueDate
        }

        var monthlyTotals: [MonthlySpending] = []
        // Iterate through the last 6 completed months
        for i in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: endOfPreviousMonth),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else { 
                continue 
            }
            let total = spendingByMonth[startOfMonth]?.reduce(0, { $0 + $1.amount }) ?? 0
            monthlyTotals.append(MonthlySpending(month: startOfMonth, totalAmount: total, currency: selectedCurrency))
        }
        return monthlyTotals.sorted { $0.month < $1.month }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if payments.isEmpty {
                        ContentUnavailableView("Sin Datos", systemImage: "chart.pie", description: Text("Añade algunos pagos para ver las estadísticas."))
                            .foregroundColor(Color("AppTextSecondary"))
                            .padding(.top, 100)
                    } else {
                        // Header con filtro de tiempo
                        VStack(spacing: 16) {
                            Picker("Período", selection: $selectedFilter.animation()) {
                                ForEach(StatsFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Selector de moneda con diseño de tabs
                            HStack(spacing: 0) {
                                // Tab Soles
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCurrency = .pen
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("Soles")
                                                .font(.subheadline)
                                                .fontWeight(selectedCurrency == .pen ? .semibold : .regular)
                                            Text("S/")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        if selectedCurrency == .pen {
                                            Text("\(totalSpending, format: .number.precision(.fractionLength(2)))")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedCurrency == .pen ? Color("AppPrimary").opacity(0.1) : Color.clear)
                                    .foregroundColor(selectedCurrency == .pen ? Color("AppPrimary") : Color("AppTextSecondary"))
                                }
                                .disabled(!hasPENPayments)
                                .opacity(hasPENPayments ? 1.0 : 0.5)
                                
                                // Tab Dólares
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCurrency = .usd
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("Dólares")
                                                .font(.subheadline)
                                                .fontWeight(selectedCurrency == .usd ? .semibold : .regular)
                                            Text("$")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        if selectedCurrency == .usd {
                                            Text("\(totalSpending, format: .number.precision(.fractionLength(2)))")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedCurrency == .usd ? Color("AppPrimary").opacity(0.1) : Color.clear)
                                    .foregroundColor(selectedCurrency == .usd ? Color("AppPrimary") : Color("AppTextSecondary"))
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
                        .padding(.bottom)
                        
                        if categoryData.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color("AppTextSecondary"))
                                Text("No hay pagos en \(selectedCurrency == .pen ? "Soles" : "Dólares")")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                Text("para \"\(selectedFilter.rawValue)\"")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // --- SECCIÓN GRÁFICO DE TORTA ---
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
                            .padding(.vertical)
                            
                            // --- SECCIÓN GRÁFICO DE BARRAS ---
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Últimos 6 Meses")
                                    .font(.title3).bold()
                                    .foregroundColor(Color("AppTextPrimary"))
                                    .padding(.horizontal)
                                
                                Chart(monthlySpendingData) { data in
                                    BarMark(
                                        x: .value("Mes", data.month, unit: .month),
                                        y: .value("Total", data.totalAmount)
                                    )
                                    .foregroundStyle(Color("AppPrimary").gradient)
                                    .cornerRadius(6)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: monthlySpendingData.count)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                                    }
                                }
                                .frame(height: 220)
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Estadísticas")
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Payment.self], inMemory: true)
}
