import SwiftUI

struct HistoryEmptyView: View {
    var body: some View {
        GenericEmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No hay pagos en el historial",
            description: "Los pagos completados y vencidos aparecerán aquí"
        )
    }
}
