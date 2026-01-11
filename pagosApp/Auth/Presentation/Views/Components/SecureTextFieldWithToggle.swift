import SwiftUI

struct SecureTextFieldWithToggle: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isSecure: Bool
    let textContentType: UITextContentType?
    let isDisabled: Bool

    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
            }

            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .padding()
        .background(Color("AppBackground"))
        .cornerRadius(10)
        .disabled(isDisabled)
    }
}
