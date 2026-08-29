import SwiftUI

struct CardsListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State var viewModel: CardsListViewModel
    @State private var showingAddCardSheet = false
    @State private var cardPendingDelete: CreditCard?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.cards.isEmpty && !viewModel.isLoading {
                    GenericEmptyStateView(
                        icon: "creditcard",
                        title: L10n.Cards.emptyTitle,
                        description: L10n.Cards.emptyDescription
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.cards) { card in
                                CreditCardCellView(card: card)
                                    .contentShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture {
                                        Task { await viewModel.revealCard(card) }
                                    }
                                    .contextMenu {
                                        Button {
                                            Task { await viewModel.startEditingCard(card) }
                                        } label: {
                                            Label(L10n.Cards.Edit.button, systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            cardPendingDelete = card
                                        } label: {
                                            Label(L10n.Cards.Delete.button, systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.Cards.listTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCardSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.fetchCards()
            }
            .refreshable {
                await viewModel.fetchCards()
            }
            .sheet(isPresented: $showingAddCardSheet) {
                AddCardView(onCardSaved: {
                    Task { await viewModel.fetchCards() }
                })
            }
            .sheet(isPresented: $viewModel.showingRevealSheet) {
                if let card = viewModel.revealedCard, let data = viewModel.revealedData {
                    CardRevealSheetView(card: card, data: data)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
                }
            }
            .onChange(of: viewModel.showingRevealSheet) { _, isPresented in
                if !isPresented {
                    viewModel.dismissRevealSheet()
                }
            }
            .sheet(isPresented: $viewModel.showingEditSheet) {
                if let card = viewModel.editingCard, let data = viewModel.editingSensitiveData {
                    AddCardView(
                        cardToEdit: card,
                        sensitiveDataToEdit: data,
                        onCardSaved: {
                            Task { await viewModel.fetchCards() }
                        }
                    )
                }
            }
            .onChange(of: viewModel.showingEditSheet) { _, isPresented in
                if !isPresented {
                    viewModel.dismissEditSheet()
                }
            }
            .alert(
                L10n.Cards.Delete.title,
                isPresented: Binding(
                    get: { cardPendingDelete != nil },
                    set: { if !$0 { cardPendingDelete = nil } }
                )
            ) {
                Button(L10n.General.cancel, role: .cancel) { cardPendingDelete = nil }
                Button(L10n.Cards.Delete.button, role: .destructive) {
                    if let card = cardPendingDelete {
                        Task { await viewModel.deleteCard(card) }
                    }
                    cardPendingDelete = nil
                }
            } message: {
                Text(L10n.Cards.Delete.message)
            }
            .alert(
                viewModel.errorMessage ?? "",
                isPresented: Binding(
                    get: { viewModel.showError },
                    set: { viewModel.showError = $0 }
                )
            ) {
                Button(L10n.General.ok, role: .cancel) {}
            }
        }
    }
}
