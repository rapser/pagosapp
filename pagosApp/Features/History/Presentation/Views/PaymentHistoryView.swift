import SwiftUI

struct PaymentHistoryView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: PaymentHistoryViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    HistoryContentView(viewModel: viewModel)
                } else {
                    ProgressView(L10n.History.loading)
                }
            }
        }
        .task {
            // Modern iOS 18 pattern: use .task for async initialization
            guard viewModel == nil else { return }

            viewModel = dependencies.historyDependencyContainer.makePaymentHistoryViewModel()
            // Fetch initial data (moved from ViewModel init)
            await viewModel?.fetchPayments()
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


struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}