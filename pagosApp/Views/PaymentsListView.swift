import SwiftUI
import SwiftData

struct PaymentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PaymentsListViewModel
    @State private var showingAddPaymentSheet = false

    init() {
        // Create a temporary placeholder - will be replaced with actual context in body
        let container = try! ModelContainer(for: Payment.self)
        let context = ModelContext(container)
        _viewModel = StateObject(wrappedValue: PaymentsListViewModel(modelContext: context))
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Filtrar", selection: $viewModel.selectedFilter) {
                    ForEach(PaymentFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView("Sincronizando...")
                } else {
                    List {
                        ForEach(viewModel.filteredPayments) { payment in
                            NavigationLink(destination: EditPaymentView(payment: payment)) {
                                PaymentRowView(payment: payment)
                                    .onTapGesture {
                                        viewModel.togglePaymentStatus(payment)
                                    }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deletePayment(payment)
                                } label: {
                                    Label("Borrar", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Mis Pagos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPaymentSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AppPrimary"))
                    }
                }
            }
            .sheet(isPresented: $showingAddPaymentSheet) {
                AddPaymentView()
                    .onDisappear {
                        viewModel.refresh()
                    }
            }
        }
    }
}