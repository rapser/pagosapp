import SwiftUI

struct HistoryFilterPicker: View {
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
