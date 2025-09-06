import SwiftUI
import Charts
import SwiftData

/// Estructura para almacenar los datos agregados para el gráfico.
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: PaymentCategory
    let totalAmount: Double
}

/// Estructura para almacenar los datos de gastos mensuales para el gráfico de barras.
struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let totalAmount: Double
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
    
    /// Filtra los pagos según la selección del usuario (mes, año o todos).
    private var filteredPayments: [Payment] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .month:
            return payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
        case .year:
            return payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .year) }
        case .all:
            return payments
        }
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
            CategorySpending(category: category, totalAmount: total)
        }.sorted { $0.totalAmount > $1.totalAmount }
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
        let relevantPayments = payments.filter { payment in
            let paymentStartOfDay = calendar.startOfDay(for: payment.dueDate)
            let isRelevant = paymentStartOfDay >= startOfPeriod && paymentStartOfDay <= endOfPreviousMonth
            return isRelevant
        }

        // Group payments by the start of their month
        let spendingByMonth = Dictionary(grouping: relevantPayments) { payment in
            calendar.date(from: calendar.dateComponents([.year, .month], from: payment.dueDate))!
        }

        var monthlyTotals: [MonthlySpending] = []
        // Iterate through the last 6 completed months
        for i in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: endOfPreviousMonth) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let total = spendingByMonth[startOfMonth]?.reduce(0, { $0 + $1.amount }) ?? 0
            monthlyTotals.append(MonthlySpending(month: startOfMonth, totalAmount: total))
        }
        return monthlyTotals.sorted { $0.month < $1.month }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Picker para seleccionar el filtro de tiempo.
                    Picker("Filtrar por", selection: $selectedFilter.animation()) {
                        ForEach(StatsFilter.allCases) {
                            filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if payments.isEmpty {
                        ContentUnavailableView("Sin Datos", systemImage: "chart.pie", description: Text("Añade algunos pagos para ver las estadísticas."))
                            .foregroundColor(Color("AppTextSecondary")) // Themed color
                    } else {
                        // --- SECCIÓN GRÁFICO DE TORTA ---
                        Text("Gastos por Categoría")
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.top, .horizontal])
                            .foregroundColor(Color("AppTextPrimary")) // Themed color
                        
                        if categoryData.isEmpty {
                            Text("No hay datos para \"\(selectedFilter.rawValue)\"")
                                .foregroundStyle(Color("AppTextSecondary")) // Themed color
                                .frame(height: 300)
                        } else {
                            Chart(categoryData) { data in
                                SectorMark(
                                    angle: .value("Monto", data.totalAmount),
                                    innerRadius: .ratio(0.618),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("Categoría", data.category.rawValue))
                            }
                            .frame(height: 300)
                            .chartLegend(position: .bottom, alignment: .center)
                            .padding()

                            List(categoryData) { data in
                                HStack {
                                    Text(data.category.rawValue)
                                        .foregroundColor(Color("AppTextPrimary")) // Themed color
                                    Spacer()
                                    Text(data.totalAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .foregroundColor(Color("AppTextPrimary")) // Themed color
                                }.padding(.horizontal)
                            }
                            .frame(height: CGFloat(categoryData.count) * 50)
                        }
                        
                        Divider().padding()
                        
                        // --- SECCIÓN GRÁFICO DE BARRAS ---
                        Text("Historial de Gastos Mensuales")
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .foregroundColor(Color("AppTextPrimary")) // Themed color
                        
                        Chart(monthlySpendingData) { data in
                            BarMark(
                                x: .value("Mes", data.month, unit: .month),
                                y: .value("Total", data.totalAmount)
                            )
                            .foregroundStyle(Color("AppPrimary").gradient) // Themed color
                            .cornerRadius(6)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: monthlySpendingData.count)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                            }
                        }
                        .frame(height: 250)
                        .padding()
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