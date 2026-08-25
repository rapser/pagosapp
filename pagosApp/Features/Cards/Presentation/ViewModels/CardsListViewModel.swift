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

    func deleteCard(_ card: CreditCard) async {
        cards.removeAll { $0.id == card.id }

        let result = await deleteCardUseCase.execute(cardId: card.id)
        switch result {
        case .success:
            break
        case .failure(let error):
            cards.append(card)
            setError(CardErrorMessageMapper.message(for: error))
        }
    }
}
