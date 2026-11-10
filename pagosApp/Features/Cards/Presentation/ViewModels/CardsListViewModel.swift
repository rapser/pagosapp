//
//  CardsListViewModel.swift
//  pagosApp
//
//  ViewModel for CardsListView using Clean Architecture
//

import Foundation

@MainActor
@Observable
final class CardsListViewModel: BaseViewModel {
    var cards: [CreditCard] = []

    var revealedCard: CreditCard?
    var revealedCardNumber: String?
    /// Only loaded after a second, dedicated Face ID check (`revealPin`).
    var revealedPin: String?
    var isRevealingPin = false
    var showingRevealSheet = false

    var editingCard: CreditCard?
    var editingSensitiveData: CreditCardSensitiveData?
    var showingEditSheet = false

    private let getAllCardsUseCase: GetAllCreditCardsUseCase
    private let deleteCardUseCase: DeleteCreditCardUseCase
    private let revealSensitiveDataUseCase: RevealCreditCardSensitiveDataUseCase

    init(
        getAllCardsUseCase: GetAllCreditCardsUseCase,
        deleteCardUseCase: DeleteCreditCardUseCase,
        revealSensitiveDataUseCase: RevealCreditCardSensitiveDataUseCase
    ) {
        self.getAllCardsUseCase = getAllCardsUseCase
        self.deleteCardUseCase = deleteCardUseCase
        self.revealSensitiveDataUseCase = revealSensitiveDataUseCase
        super.init(category: "CardsListViewModel")
    }

    func fetchCards() async {
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getAllCardsUseCase.execute()
                switch result {
                case .success(let fetchedCards):
                    self.cards = fetchedCards
                    return fetchedCards
                case .failure(let error):
                    throw error
                }
            },
            onError: { error in
                if let cardError = error as? CardError {
                    self.setError(CardErrorMessageMapper.message(for: cardError))
                }
            }
        )
    }

    /// First Face ID/Touch ID check: on success shows the reveal bottom sheet with the
    /// card number only. The PIN stays in Keychain (shown as a skeleton) until `revealPin`.
    /// On failure/cancel, no sensitive data is set and no sheet is shown.
    func revealCard(_ card: CreditCard) async {
        let result = await revealSensitiveDataUseCase.executeCardNumber(
            cardId: card.id,
            reason: L10n.Cards.biometricReason
        )

        switch result {
        case .success(let cardNumber):
            revealedCard = card
            revealedCardNumber = cardNumber
            revealedPin = nil
            showingRevealSheet = true
        case .failure(let error):
            setError(CardErrorMessageMapper.message(for: error))
        }
    }

    /// Second, independent Face ID/Touch ID check that loads the PIN of the card
    /// currently shown in the reveal sheet. On failure/cancel the PIN stays hidden.
    func revealPin() async {
        guard let card = revealedCard, revealedPin == nil, !isRevealingPin else { return }

        isRevealingPin = true
        defer { isRevealingPin = false }

        let result = await revealSensitiveDataUseCase.executePin(
            cardId: card.id,
            reason: L10n.Cards.Reveal.pinBiometricReason
        )

        // The sheet may have been dismissed (or another card shown) while Face ID was up.
        guard showingRevealSheet, revealedCard?.id == card.id else { return }

        if case .success(let pin) = result {
            revealedPin = pin
        }
    }

    func hidePin() {
        revealedPin = nil
    }

    func dismissRevealSheet() {
        showingRevealSheet = false
        revealedCard = nil
        revealedCardNumber = nil
        revealedPin = nil
    }

    /// Requests Face ID/Touch ID, and on success shows the edit form pre-filled with
    /// the card's current secrets. On failure/cancel, the editor never opens.
    func startEditingCard(_ card: CreditCard) async {
        let result = await revealSensitiveDataUseCase.execute(
            cardId: card.id,
            reason: L10n.Cards.Edit.biometricReason
        )

        switch result {
        case .success(let data):
            editingCard = card
            editingSensitiveData = data
            showingEditSheet = true
        case .failure(let error):
            setError(CardErrorMessageMapper.message(for: error))
        }
    }

    func dismissEditSheet() {
        showingEditSheet = false
        editingCard = nil
        editingSensitiveData = nil
    }

    /// Requires a Face ID/Touch ID confirmation (enforced inside the use case) before
    /// the card is actually removed.
    func deleteCard(_ card: CreditCard) async {
        let result = await deleteCardUseCase.execute(cardId: card.id, reason: L10n.Cards.Delete.biometricReason)
        switch result {
        case .success:
            cards.removeAll { $0.id == card.id }
        case .failure(let error):
            setError(CardErrorMessageMapper.message(for: error))
        }
    }
}
