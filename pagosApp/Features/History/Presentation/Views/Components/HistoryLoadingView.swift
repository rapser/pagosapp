import SwiftUI

struct HistoryLoadingView: View {
    var body: some View {
        LoadingStateView(style: .inline, message: L10n.History.loading)
    }
}
