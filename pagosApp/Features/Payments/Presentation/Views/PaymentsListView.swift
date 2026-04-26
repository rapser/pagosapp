import SwiftUI

struct PaymentsListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var showingAddPaymentSheet = false

    var body: some View {
        PaymentsListContentWrapper(showingAddPaymentSheet: $showingAddPaymentSheet)
            .environment(dependencies)
    }
}

// MARK: - Content Wrapper (handles initialization)
private struct PaymentsListContentWrapper: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: PaymentsListViewModel?
    @Binding var showingAddPaymentSheet: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    PaymentsListContent(
                        viewModel: viewModel,
                        showingAddPaymentSheet: $showingAddPaymentSheet
                    )
                } else {
                    ProgressView(L10n.General.loading)
                }
            }
            .navigationTitle(L10n.Payments.List.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AddButton(action: { showingAddPaymentSheet = true })
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = dependencies.paymentDependencyContainer.makePaymentsListViewModel(
                calendarEventDataSource: dependencies.calendarEventDataSource,
                notificationDataSource: dependencies.notificationDataSource
            )
            await viewModel?.fetchPayments(showLoading: false)
        }
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentView()
        }
        .onChange(of: showingAddPaymentSheet) { _, isPresented in
            // Refresh when sheet is dismissed
            if !isPresented {
                Task {
                    await viewModel?.fetchPayments(showLoading: false)
                }
            }
        }
    }
}

// MARK: - Main Content (with ViewModel)
private struct PaymentsListContent: View {
    @Bindable var viewModel: PaymentsListViewModel
    @Binding var showingAddPaymentSheet: Bool

    var body: some View {
        // Main container that fills all available space
        VStack(spacing: 0) {
            // Segmented Control - Fixed at top
            FilterPicker(selectedFilter: $viewModel.selectedFilter)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemGroupedBackground))

            // TableView/List - Fills remaining space
            if viewModel.isLoading {
                ProgressView(L10n.Payments.List.syncing)
            } else {
                PaymentsList(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Filter Picker (Segmented Control)
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

// MARK: - Payments List (TableView)
private struct PaymentsList: View {
    @Bindable var viewModel: PaymentsListViewModel

    var body: some View {
        List {
            ForEach(viewModel.groupedPayments) { item in
                switch item {
                case .group(let group):
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
                            Task {
                                await viewModel.togglePaymentStatus(payment)
                            }
                        })
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deletePayment(payment)
                            }
                        } label: {
                            Label(L10n.General.delete, systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func editViewForGroup(_ group: PaymentGroupUI) -> some View {
        if let firstPayment = group.penPayment ?? group.usdPayment {
            EditPaymentView(payment: firstPayment)
        }
    }
}

// MARK: - Add Button
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
