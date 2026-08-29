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

    var revealedData: CreditCardSensitiveData?
    var revealedCard: CreditCard?
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

    /// Requests Face ID/Touch ID, and on success shows the reveal bottom sheet.
    /// On failure/cancel, no sensitive data is set and no sheet is shown.
    func revealCard(_ card: CreditCard) async {
        let result = await revealSensitiveDataUseCase.execute(
            cardId: card.id,
            reason: L10n.Cards.biometricReason
        )

        switch result {
        case .success(let data):
            revealedCard = card
            revealedData = data
            showingRevealSheet = true
        case .failure(let error):
            setError(CardErrorMessageMapper.message(for: error))
        }
    }

    func dismissRevealSheet() {
        showingRevealSheet = false
        revealedData = nil
        revealedCard = nil
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
