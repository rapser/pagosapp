import SwiftUI

struct HistoryFilterPicker: View {
    @Binding var selectedFilter: PaymentHistoryFilter

    var body: some View {
        Picker(L10n.Payments.List.filter, selection: $selectedFilter) {
            ForEach(PaymentHistoryFilter.allCases) { filter in
                Text(L10n.History.filterDisplayName(filter)).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
