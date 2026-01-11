import SwiftUI

struct HistoryListView: View {
    let payments: [PaymentUI]
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(payments) { payment in
                PaymentRowView(payment: payment, onToggleStatus: {})
            }
        }
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
    }
}
