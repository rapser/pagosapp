import SwiftUI

struct AddCardView: View {
    @Environment(AppDependencies.self) private var dependencies
    var cardToEdit: CreditCard?
    var sensitiveDataToEdit: CreditCardSensitiveData?
    var onCardSaved: (() -> Void)?

    var body: some View {
        AddCardContentWrapper(cardToEdit: cardToEdit, sensitiveDataToEdit: sensitiveDataToEdit, onCardSaved: onCardSaved)
            .environment(dependencies)
    }
}

// MARK: - Content Wrapper (handles initialization with .task)
private struct AddCardContentWrapper: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: AddCardViewModel?
    let cardToEdit: CreditCard?
    let sensitiveDataToEdit: CreditCardSensitiveData?
    let onCardSaved: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    AddCardForm(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            let newViewModel = dependencies.cardDependencyContainer.makeAddCardViewModel()
            if let cardToEdit, let sensitiveDataToEdit {
                newViewModel.loadForEditing(cardToEdit, sensitiveData: sensitiveDataToEdit)
            }
            newViewModel.onCardSaved = onCardSaved
            viewModel = newViewModel
        }
    }
}

// MARK: - Form View
private struct AddCardForm: View {
    @Bindable var viewModel: AddCardViewModel
    let dismiss: DismissAction

    /// Includes the card's current expiration year even if it's already in the past,
    /// so editing an older card doesn't silently snap its year picker to another value.
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let start = min(currentYear, viewModel.expirationYear)
        let end = max(currentYear + 15, viewModel.expirationYear)
        return Array(start...end)
    }

    var body: some View {
        Form {
            Section {
                Picker(L10n.Cards.Add.bankLabel, selection: $viewModel.bank) {
                    ForEach(Bank.allCases, id: \.self) { bank in
                        Text(bank.rawValue).tag(bank)
                    }
                }

                if viewModel.bank == .other {
                    TextField(L10n.Cards.Add.bankOtherPlaceholder, text: $viewModel.customBankName)
                }
            }

            Section {
                TextField(L10n.Cards.Add.cardNumberLabel, text: $viewModel.cardNumber)
                    .keyboardType(.numberPad)

                if viewModel.detectedBrand != .unknown && !viewModel.cardNumber.isEmpty {
                    HStack {
                        Text(L10n.Cards.Add.brandLabel)
                        Spacer()
                        Text(viewModel.detectedBrand.displayName)
                            .foregroundStyle(.secondary)
                    }
                }

                SecureField(L10n.Cards.Add.pinLabel, text: $viewModel.pin)
                    .keyboardType(.numberPad)
            }

            Section {
                Picker(L10n.Cards.Add.expirationMonthLabel, selection: $viewModel.expirationMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(String(format: "%02d", month)).tag(month)
                    }
                }
                Picker(L10n.Cards.Add.expirationYearLabel, selection: $viewModel.expirationYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } header: {
                Text(L10n.Cards.Add.expirationLabel)
            } footer: {
                Text(L10n.Cards.Add.cvvFooter)
            }
        }
        .navigationTitle(viewModel.isEditing ? L10n.Cards.Edit.title : L10n.Cards.Add.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.General.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.General.save) {
                    Task {
                        await viewModel.saveCard()
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
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
