
import SwiftUI

struct AddPaymentView: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        AddPaymentContentWrapper()
            .environment(dependencies)
    }
}

// MARK: - Content Wrapper (handles initialization with .task)
private struct AddPaymentContentWrapper: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: AddPaymentViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    AddPaymentForm(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            // Modern iOS 18 pattern: use .task for initialization
            guard viewModel == nil else { return }

            viewModel = dependencies.paymentDependencyContainer.makeAddPaymentViewModel(
                calendarEventDataSource: dependencies.calendarEventDataSource,
                notificationDataSource: dependencies.notificationDataSource
            )
        }
    }
}

// MARK: - Form View (separated for clarity)
private struct AddPaymentForm: View {
    @Bindable var viewModel: AddPaymentViewModel
    let dismiss: DismissAction

    var body: some View {
        Form {
            PaymentDetailsSection(
                name: $viewModel.name,
                category: $viewModel.category,
                dueDate: $viewModel.dueDate
            )

            if viewModel.showDualCurrency {
                DualCurrencyAmountSection(
                    amountPEN: $viewModel.amount,
                    amountUSD: $viewModel.amountUSD
                )
            } else {
                SingleCurrencyAmountSection(
                    currency: $viewModel.currency,
                    amount: $viewModel.amount
                )
            }
        }
        .navigationTitle(L10n.Payments.Add.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.General.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.General.save) {
                    Task {
                        await viewModel.savePayment()
                        dismiss()
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView(L10n.Payments.Edit.saving)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
}

//#Preview {
//    AddPaymentView()
//        .modelContainer(for: [Payment.self], inMemory: true)
//}
