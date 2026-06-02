import SwiftUI

/// Full-width primary action button intended for `.safeAreaInset(edge: .bottom)`.
/// - Sits above the safe area automatically — home indicator is never covered.
/// - The extra bottom padding adds breathing room between the button and the
///   system safe area edge, consistent across all device sizes.
struct StickyActionButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    init(title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDisabled)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(Color(UIColor.systemBackground))
        }
    }
}
