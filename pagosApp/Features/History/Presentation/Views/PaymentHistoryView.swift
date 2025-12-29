import SwiftUI

struct PaymentHistoryView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: PaymentHistoryViewModel?

    init() {

        // Configurar segmented control con soporte para modo oscuro
        UISegmentedControl.appearance().backgroundColor = UIColor(named: "SegmentedBackground")

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            } else {
                return .white
            }
        }

        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .white
                } else {
                    return UIColor(named: "AppPrimary") ?? .systemBlue
                }
            }
        ], for: .selected)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    HistoryContentView(viewModel: viewModel)
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.historyDependencyContainer.makePaymentHistoryViewModel()
            }
        }
        .onChange(of: viewModel?.selectedFilter) { oldValue, newValue in
            if let newValue = newValue, let vm = viewModel {
                Task {
                    await vm.updateFilter(newValue)
                }
            }
        }
    }
}

// MARK: - Subviews

private struct HistoryContentView: View {
    @Bindable var viewModel: PaymentHistoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            HistoryFilterPicker(selectedFilter: $viewModel.selectedFilter)

            HistoryBodyContent(viewModel: viewModel)
        }
        .navigationTitle("Historial de Pagos")
    }
}

private struct HistoryFilterPicker: View {
    @Binding var selectedFilter: PaymentHistoryFilter

    var body: some View {
        Picker("Filtrar", selection: $selectedFilter) {
            ForEach(PaymentHistoryFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct HistoryBodyContent: View {
    @Bindable var viewModel: PaymentHistoryViewModel

    var body: some View {
        if viewModel.isLoading {
            HistoryLoadingView()
        } else if viewModel.filteredPayments.isEmpty {
            HistoryEmptyView()
        } else {
            HistoryListView(payments: viewModel.filteredPayments, onRefresh: {
                await viewModel.refresh()
            })
        }
    }
}

private struct HistoryLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView("Cargando historial...")
            Spacer()
        }
    }
}

private struct HistoryEmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(Color("AppTextSecondary"))

                Text("No hay pagos en el historial")
                    .font(.headline)
                    .foregroundColor(Color("AppTextPrimary"))

                Text("Los pagos completados y vencidos aparecerán aquí")
                    .font(.subheadline)
                    .foregroundColor(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

private struct HistoryListView: View {
    let payments: [Payment]
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(payments) { payment in
                PaymentRowView(payment: payment, onToggleStatus: {})
                    .opacity(payment.isPaid ? 1.0 : 0.7)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}