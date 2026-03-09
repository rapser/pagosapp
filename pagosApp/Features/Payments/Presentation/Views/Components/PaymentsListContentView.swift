import SwiftUI

struct PaymentsListContentView: View {
    @Bindable var viewModel: PaymentsListViewModel
    @Binding var showingAddPaymentSheet: Bool

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingIndicator()
            } else {
                PaymentsList(
                    viewModel: viewModel,
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
                .safeAreaInset(edge: .top, spacing: 0) {
                    FilterPicker(selectedFilter: $viewModel.selectedFilter)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemGroupedBackground))
                }
            }
        }
        .navigationTitle(L10n.Payments.List.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AddButton(action: { showingAddPaymentSheet = true })
            }
        }
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentView()
        }
        .onChange(of: showingAddPaymentSheet) { _, isPresented in
            // Refresh when sheet is dismissed
            if !isPresented {
                Task {
                    await viewModel.fetchPayments(showLoading: false)
                }
            }
        }
    }
}

private struct FilterPicker: View {
    @Binding var selectedFilter: PaymentFilterUI

    var body: some View {
        Picker(L10n.Payments.List.filter, selection: $selectedFilter) {
            ForEach(PaymentFilterUI.allCases) { filter in
                Text(L10n.Payments.filterDisplayName(filter)).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct LoadingIndicator: View {
    var body: some View {
        LoadingStateView(style: .inline, message: L10n.Payments.List.syncing)
    }
}

private struct PaymentsList: View {
    @Bindable var viewModel: PaymentsListViewModel
    let onToggleStatus: (PaymentUI) -> Void
    let onDelete: (PaymentUI) -> Void
    let onRefresh: () -> Void

    var body: some View {
        let items = viewModel.groupedPayments

        List {
            ForEach(items) { item in
                switch item {
                case .group(let group):
                    // For grouped payments, navigate to first payment in group
                    NavigationLink(destination: editViewForGroup(group)) {
                        PaymentGroupRowView(group: group, onToggleStatus: {
                            Task {
                                await viewModel.toggleGroupStatus(group)
                            }
                        })
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteGroup(group)
                            }
                        } label: {
                            Label(L10n.General.delete, systemImage: "trash.fill")
                        }
                    }

                case .individual(let payment):
                    NavigationLink(destination: EditPaymentView(payment: payment)) {
                        PaymentRowView(payment: payment, onToggleStatus: {
                            onToggleStatus(payment)
                        })
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            onDelete(payment)
                        } label: {
                            Label(L10n.General.delete, systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            onRefresh()
        }
    }

    @ViewBuilder
    private func editViewForGroup(_ group: PaymentGroupUI) -> some View {
        // Navigate to the first available payment in the group
        if let firstPayment = group.penPayment ?? group.usdPayment {
            EditPaymentView(payment: firstPayment)
        } else {
            EmptyView()
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
