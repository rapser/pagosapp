import Foundation
import LocalAuthentication

/// Storage for the sensitive fields of a credit card (full number + PIN), kept out
/// of SwiftData entirely. Implementations must gate reads behind biometric auth.
protocol CreditCardSensitiveDataSource {
    func save(cardId: UUID, cardNumber: String, pin: String) -> Bool
    func retrieve(cardId: UUID, context: LAContext?) -> (cardNumber: String, pin: String)?
    @discardableResult
    func delete(cardId: UUID) -> Bool
}
