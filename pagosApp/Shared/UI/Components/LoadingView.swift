
import SwiftUI

struct LoadingView: View {
    var message: String?

    var body: some View {
        ZStack {
            // Semi-transparent dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Loading card
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AppPrimary")))
                    .scaleEffect(1.5)

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("AppBackground"))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        LoadingView(message: "Cerrando sesión...")
    }
}
