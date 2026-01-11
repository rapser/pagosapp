import SwiftUI

struct HistoryContentView: View {
    @Bindable var viewModel: PaymentHistoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            HistoryFilterPicker(selectedFilter: $viewModel.selectedFilter)

            HistoryBodyContent(viewModel: viewModel)
        }
        .navigationTitle("Historial de Pagos")
    }
}
