import SwiftUI

struct HistoryEmptyView: View {
    var body: some View {
        GenericEmptyStateView(
            icon: "clock.arrow.circlepath",
            title: L10n.History.emptyTitle,
            description: L10n.History.emptyDescription
        )
    }
}
