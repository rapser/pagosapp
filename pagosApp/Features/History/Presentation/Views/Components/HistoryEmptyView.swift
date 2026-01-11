import SwiftUI

struct HistoryEmptyView: View {
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
