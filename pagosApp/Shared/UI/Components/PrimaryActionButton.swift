import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let loadingTitle: String
    let isLoading: Bool
    let isValid: Bool
    let backgroundColor: Color
    let action: () -> Void

    init(
        title: String,
        loadingTitle: String? = nil,
        isLoading: Bool,
        isValid: Bool,
        backgroundColor: Color = Color("AppPrimary"),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.loadingTitle = loadingTitle ?? "Cargando..."
        self.isLoading = isLoading
        self.isValid = isValid
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? loadingTitle : title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? backgroundColor : backgroundColor.opacity(0.5))
            .cornerRadius(10)
        }
        .disabled(isLoading || !isValid)
    }
}
