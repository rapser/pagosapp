import SwiftUI

struct ValidationHintRow: View {
    let isValid: Bool
    let message: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
            Text(message)
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
        }
    }
}
