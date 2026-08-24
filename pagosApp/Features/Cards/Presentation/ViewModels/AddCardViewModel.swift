//
//  AddCardViewModel.swift
//  pagosApp
//
//  ViewModel for AddCardView using Clean Architecture
//

import Foundation

@MainActor
@Observable
final class AddCardViewModel: BaseViewModel {
    // MARK: - Observable Properties (UI State)

    var bank: Bank = .bcp
    var customBankName: String = ""
    var cardNumber: String = ""
    var pin: String = ""
    var expirationMonth: Int = Calendar.current.component(.month, from: Date())
    var expirationYear: Int = Calendar.current.component(.year, from: Date())

    private let createCardUseCase: CreateCreditCardUseCase

    var onCardCreated: (() -> Void)?

    init(createCardUseCase: CreateCreditCardUseCase) {
        self.createCardUseCase = createCardUseCase
        super.init(category: "AddCardViewModel")
    }

    // MARK: - Computed Properties

    /// Live brand preview as the user types the card number.
    var detectedBrand: CardBrand {
        CardBrand.detect(from: cardNumber)
    }

    var isValid: Bool {
        let digits = cardNumber.filter(\.isNumber)
        let pinDigits = pin.filter(\.isNumber)
        guard (12...19).contains(digits.count) else { return false }
        guard pinDigits.count == pin.count, (4...6).contains(pinDigits.count) else { return false }
        if bank == .other {
            guard !customBankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        }
        return true
    }

    // MARK: - Actions

    func saveCard() async {
        guard isValid else {
            setValidationError(L10n.Cards.Errors.invalidCardNumber)
            return
        }

        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.createCardUseCase.execute(
                    bank: self.bank,
                    customBankName: self.bank == .other ? self.customBankName : nil,
                    cardNumber: self.cardNumber,
                    pin: self.pin,
                    expirationMonth: self.expirationMonth,
                    expirationYear: self.expirationYear
                )
                if case .failure(let error) = result {
                    throw error
                }
                return result
            },
            onSuccess: { _ in
                self.clearForm()
                self.onCardCreated?()
            },
            onError: { error in
                if let cardError = error as? CardError {
                    self.setError(CardErrorMessageMapper.message(for: cardError))
                }
            }
        )
    }

    func clearForm() {
        bank = .bcp
        customBankName = ""
        cardNumber = ""
        pin = ""
        expirationMonth = Calendar.current.component(.month, from: Date())
        expirationYear = Calendar.current.component(.year, from: Date())
    }
}
