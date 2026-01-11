import SwiftUI

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isDisabled: Bool

    init(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isDisabled: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isDisabled = isDisabled
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
            .autocorrectionDisabled(keyboardType == .emailAddress)
            .padding()
            .background(Color("AppBackground"))
            .cornerRadius(10)
            .disabled(isDisabled)
    }
}
