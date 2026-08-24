import SwiftUI

struct AddCardView: View {
    @Environment(AppDependencies.self) private var dependencies
    var onCardCreated: (() -> Void)?

    var body: some View {
        AddCardContentWrapper(onCardCreated: onCardCreated)
            .environment(dependencies)
    }
}

// MARK: - Content Wrapper (handles initialization with .task)
private struct AddCardContentWrapper: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: AddCardViewModel?
    let onCardCreated: (() -> Void)?

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
            viewModel = dependencies.cardDependencyContainer.makeAddCardViewModel()
            viewModel?.onCardCreated = onCardCreated
        }
    }
}

// MARK: - Form View
private struct AddCardForm: View {
    @Bindable var viewModel: AddCardViewModel
    let dismiss: DismissAction

    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 15))
    }()

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
        .navigationTitle(L10n.Cards.Add.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.General.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.General.save) {
                    Task {
                        await viewModel.saveCard()
                        dismiss()
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
    }
}
