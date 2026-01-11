import SwiftUI

struct HistoryBodyContent: View {
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
