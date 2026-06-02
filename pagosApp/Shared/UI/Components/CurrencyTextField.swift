import SwiftUI
import UIKit

/// Banking-style currency input field.
/// Digits shift from right: typing "5" shows "0.05", then "0" → "0.50", then "0" → "5.00".
/// Backspace reverses the shift. No decimal key needed.
///
/// Binding semantics: `amount` holds a decimal string ("5.00") when cents > 0, or "" when empty.
struct CurrencyTextField: View {
    @Binding var amount: String

    var body: some View {
        CurrencyInputRepresentable(amount: $amount)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - UIViewRepresentable

private struct CurrencyInputRepresentable: UIViewRepresentable {
    @Binding var amount: String

    func makeCoordinator() -> Coordinator {
        Coordinator(amount: $amount)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.textAlignment = .right
        tf.font = UIFont.preferredFont(forTextStyle: .title3)
        tf.textColor = UIColor.label
        tf.backgroundColor = .clear
        tf.delegate = context.coordinator
        tf.text = context.coordinator.displayText()

        // Horizontal padding inside the field
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always
        let padRight = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.rightView = padRight
        tf.rightViewMode = .always

        // Done button for numberPad (no Return key)
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
            self.cents = CurrencyInputRepresentable.parseCents(from: amount.wrappedValue)
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
                // Backspace: drop last cent digit
                cents = cents / 10
            } else if string.count == 1, let digit = Int(string), string.allSatisfy(\.isNumber) {
                // New digit: shift left and append
                let newCents = cents * 10 + digit
                guard newCents <= maxCents else { return false }
                cents = newCents
            }

            let display = displayText()
            textField.text = display
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
