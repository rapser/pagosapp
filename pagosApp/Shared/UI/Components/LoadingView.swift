import SwiftUI

/// Overlay loading (kept for backward compatibility); uses LoadingStateView internally
struct LoadingView: View {
    var message: String?

    var body: some View {
        LoadingStateView(style: .overlay, message: message)
    }
}

#Preview {
    ZStack {
        Color.gray
        LoadingView(message: "Cerrando sesión...")
    }
}
