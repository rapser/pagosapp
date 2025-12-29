import SwiftUI

struct PaymentsListContentView: View {
    @Bindable var viewModel: PaymentsListViewModel
    @Binding var showingAddPaymentSheet: Bool

    var body: some View {
        VStack {
            FilterPicker(selectedFilter: $viewModel.selectedFilter)

            if viewModel.isLoading {
                LoadingIndicator()
            } else {
                PaymentsList(
                    payments: viewModel.filteredPayments,
                    onToggleStatus: { payment in
                        Task {
                            await viewModel.togglePaymentStatus(payment)
                        }
                    },
                    onDelete: { payment in
                        Task {
                            await viewModel.deletePayment(payment)
                        }
                    },
                    onRefresh: {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            }
        }
        .navigationTitle("Mis Pagos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AddButton(action: { showingAddPaymentSheet = true })
            }
        }
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentView()
                .onDisappear {
                    Task {
                        await viewModel.refresh()
                    }
                }
        }
    }
}

private struct FilterPicker: View {
    @Binding var selectedFilter: PaymentFilter

    var body: some View {
        Picker("Filtrar", selection: $selectedFilter) {
            ForEach(PaymentFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

private struct LoadingIndicator: View {
    var body: some View {
        ProgressView("Sincronizando...")
    }
}

private struct PaymentsList: View {
    let payments: [Payment]
    let onToggleStatus: (Payment) -> Void
    let onDelete: (Payment) -> Void
    let onRefresh: () -> Void

    var body: some View {
        List {
            ForEach(payments) { payment in
                NavigationLink(destination: EditPaymentView(payment: payment)) {
                    PaymentRowView(payment: payment, onToggleStatus: {
                        onToggleStatus(payment)
                    })
                }
                .swipeActions {
                    Button(role: .destructive) {
                        onDelete(payment)
                    } label: {
                        Label("Borrar", systemImage: "trash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            onRefresh()
        }
    }
}

private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundColor(primaryColor)
        }
    }

    private var primaryColor: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .white
            } else {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            }
        })
    }
}
