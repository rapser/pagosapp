import SwiftUI
import SwiftData

enum PaymentFilter: String, CaseIterable, Identifiable {
    case currentMonth = "Próximos"
    case previousMonths = "Pasados"

    var id: String { self.rawValue }
}

struct PaymentsListView: View {
    @Environment(\.modelContext) private var modelContext
    // @Query obtiene los datos de SwiftData y actualiza la vista automáticamente.
    // Los ordenamos por fecha de vencimiento.
    @Query(sort: \Payment.dueDate, order: .forward) private var payments: [Payment]
    
    @State private var showingAddPaymentSheet = false
    @State private var selectedFilter: PaymentFilter = .currentMonth

    private var filteredPayments: [Payment] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .currentMonth:
            return payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
        case .previousMonths:
            return payments.filter { $0.dueDate < calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Filtrar", selection: $selectedFilter) {
                    ForEach(PaymentFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    ForEach(filteredPayments) { payment in
                        // NavigationLink nos lleva a la vista de edición.
                        NavigationLink(destination: EditPaymentView(payment: payment)) {
                            PaymentRowView(payment: payment)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                // Find the index of the payment to delete
                                if let index = filteredPayments.firstIndex(where: { $0.id == payment.id }) {
                                    deletePayments(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Borrar", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
            }
            .navigationTitle("Mis Pagos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPaymentSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPaymentSheet) {
                AddPaymentView()
            }
        }
        .environmentObject(NotificationManager.shared) // Inject NotificationManager
        .environmentObject(EventKitManager.shared) // Inject EventKitManager
    }
    
    /// Función para eliminar pagos de la lista y de SwiftData.
    private func deletePayments(at offsets: IndexSet) {
        // Convert IndexSet to an array of payments to delete
        let paymentsToDelete = offsets.map { filteredPayments[$0] }
        
        for paymentToDelete in paymentsToDelete {
            EventKitManager.shared.removeEvent(for: paymentToDelete) // Eliminamos del calendario
            NotificationManager.shared.cancelNotification(for: paymentToDelete) // Cancelamos su notificación
            modelContext.delete(paymentToDelete) // Eliminamos de SwiftData
        }
    }
}