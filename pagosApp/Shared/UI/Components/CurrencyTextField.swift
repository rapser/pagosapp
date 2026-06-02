import SwiftUI
import UIKit

/// Banking-style currency input field.
/// Digits shift from right: typing "5" shows "0.05", then "0" → "0.50", then "0" → "5.00".
/// Backspace reverses the shift. No decimal key needed.
///
/// - "0.00" is rendered in placeholder color (light gray) until the user types a digit.
/// - Once cents > 0 the text switches to the normal label color.
/// - `amount` binding holds a decimal string ("5.00") when > 0, or "" when empty.
struct CurrencyTextField: View {
    @Binding var amount: String

    var body: some View {
        _CurrencyInput(amount: $amount)
            .frame(maxWidth: .infinity, minHeight: 44)
    }
}

// MARK: - UIViewRepresentable

private struct _CurrencyInput: UIViewRepresentable {
    @Binding var amount: String

    func makeCoordinator() -> Coordinator {
        Coordinator(amount: $amount)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.textAlignment = .left
        tf.font = UIFont.preferredFont(forTextStyle: .title3)
        tf.backgroundColor = .clear
        tf.delegate = context.coordinator

        let initialCents = context.coordinator.cents
        tf.text = context.coordinator.displayText()
        tf.textColor = initialCents > 0 ? .label : .placeholderText

        // Done button — numberPad has no Return key
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissKeyboard)
        )
        toolbar.items = [flex, done]
        tf.inputAccessoryView = toolbar

        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Sync only on external changes (e.g. resetChanges, initial load)
        let externalCents = Self.parseCents(from: amount)
        if externalCents != context.coordinator.cents {
            context.coordinator.cents = externalCents
            uiView.text = context.coordinator.displayText()
            uiView.textColor = externalCents > 0 ? .label : .placeholderText
        }
    }

    static func parseCents(from string: String) -> Int {
        guard let value = Double(string), value > 0 else { return 0 }
        return Int((value * 100).rounded())
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var amount: String
        var cents: Int
        private let maxCents = 9_999_999 // cap: 99,999.99

        init(amount: Binding<String>) {
            self._amount = amount
            self.cents = _CurrencyInput.parseCents(from: amount.wrappedValue)
        }

        func displayText() -> String {
            String(format: "%.2f", Double(cents) / 100.0)
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if string.isEmpty {
                // Backspace: drop the last cent digit
                cents = cents / 10
            } else if string.count == 1, let digit = Int(string), string.allSatisfy(\.isNumber) {
                // New digit: shift left and append
                let newCents = cents * 10 + digit
                guard newCents <= maxCents else { return false }
                cents = newCents
            }

            let display = displayText()
            textField.text = display
            textField.textColor = cents > 0 ? .label : .placeholderText
            amount = cents > 0 ? display : ""
            return false
        }

        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}
