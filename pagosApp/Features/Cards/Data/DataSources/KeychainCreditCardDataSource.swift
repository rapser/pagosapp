//
//  KeychainCreditCardDataSource.swift
//  pagosApp
//
//  Keychain implementation for credit card sensitive data (number + PIN)
//  Clean Architecture - Data Layer
//
//  Mirrors KeychainBiometricCredentialsDataSource: items are protected with
//  `.biometryCurrentSet` access control, so the OS itself requires Face ID/Touch ID
//  to read them - independent of any app-level biometric check.
//

import Foundation
import Security
import LocalAuthentication

final class KeychainCreditCardDataSource: CreditCardSensitiveDataSource {
    private static let logCategory = "KeychainCreditCardDataSource"

    private let log: DomainLogWriter
    private let service = "com.rapser.pagosApp"

    init(log: DomainLogWriter) {
        self.log = log
    }

    private func numberKey(for cardId: UUID) -> String { "card.\(cardId.uuidString).number" }
    private func pinKey(for cardId: UUID) -> String { "card.\(cardId.uuidString).pin" }

    // MARK: - Save

    func save(cardId: UUID, cardNumber: String, pin: String) -> Bool {
        guard let numberData = cardNumber.data(using: .utf8),
              let pinData = pin.data(using: .utf8) else {
            log.error("Failed to encode card secrets", category: Self.logCategory)
            return false
        }

        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &accessControlError
        ) else {
            log.error("Failed to create access control for card secrets", category: Self.logCategory)
            return false
        }

        do {
            try upsertGenericPassword(account: numberKey(for: cardId), data: numberData, accessControl: accessControl)
            do {
                try upsertGenericPassword(account: pinKey(for: cardId), data: pinData, accessControl: accessControl)
            } catch {
                log.error("Failed to save card PIN: \(error.localizedDescription)", category: Self.logCategory)
                // Best-effort rollback so we don't leave the number without a PIN
                _ = delete(cardId: cardId)
                return false
            }
        } catch {
            log.error("Failed to save card number: \(error.localizedDescription)", category: Self.logCategory)
            return false
        }

        return true
    }

    // MARK: - Retrieve

    func retrieve(cardId: UUID, context: LAContext?) -> (cardNumber: String, pin: String)? {
        guard let cardNumber = retrieveString(account: numberKey(for: cardId), context: context),
              let pin = retrieveString(account: pinKey(for: cardId), context: context) else {
            return nil
        }
        return (cardNumber, pin)
    }

    // MARK: - Delete

    @discardableResult
    func delete(cardId: UUID) -> Bool {
        let numberQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: numberKey(for: cardId)
        ]
        let pinQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: pinKey(for: cardId)
        ]

        let numberStatus = SecItemDelete(numberQuery as CFDictionary)
        let pinStatus = SecItemDelete(pinQuery as CFDictionary)

        let numberOk = numberStatus == errSecSuccess || numberStatus == errSecItemNotFound
        let pinOk = pinStatus == errSecSuccess || pinStatus == errSecItemNotFound

        if !(numberOk && pinOk) {
            log.error("Failed to delete card secrets: number=\(numberStatus), pin=\(pinStatus)", category: Self.logCategory)
        }
        return numberOk && pinOk
    }

    // MARK: - Private Helpers

    private func upsertGenericPassword(account: String, data: Data, accessControl: SecAccessControl) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessControl as String] = accessControl
            query[kSecAttrSynchronizable as String] = false

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                log.error("Failed to add keychain item (\(account)): \(addStatus)", category: Self.logCategory)
                throw NSError(domain: "KeychainCreditCardDataSource", code: Int(addStatus), userInfo: nil)
            }
            return
        }

        log.error("Failed to update keychain item (\(account)): \(updateStatus)", category: Self.logCategory)
        throw NSError(domain: "KeychainCreditCardDataSource", code: Int(updateStatus), userInfo: nil)
    }

    private func retrieveString(account: String, context: LAContext?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if let context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }
}
