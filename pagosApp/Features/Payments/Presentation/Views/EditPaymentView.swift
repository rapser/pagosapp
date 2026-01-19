
import SwiftUI

struct EditPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: EditPaymentViewModel?
    @State private var otherPayment: PaymentUI?
    @State private var isLoadingOtherPayment = false
    let payment: PaymentUI

    init(payment: PaymentUI) {
        self.payment = payment
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    EditPaymentFormView(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    Task {
                        await loadPaymentGroup()
                    }
                }
            }
        }
    }

    private func loadPaymentGroup() async {
        // If payment has a groupId, find the other payment in the group
        if let groupId = payment.groupId {
            isLoadingOtherPayment = true
            defer { isLoadingOtherPayment = false }

            let container = dependencies.paymentDependencyContainer
            let getAllPaymentsUseCase = container.makeGetAllPaymentsUseCase()
            
            let result = await getAllPaymentsUseCase.execute()
            
            switch result {
            case .success(let allPayments):
                // Convert to UI models - we need to use the mapper from the container
                // Since we can't access it directly, we'll use the PaymentsListViewModel's mapper
                // Actually, let's create a temporary mapper instance
                let mapper = PaymentUIMapper()
                let allPaymentsUI = mapper.toUI(allPayments)
                
                // Find the other payment in the group (different currency)
                let otherPaymentFound = allPaymentsUI.first { paymentUI in
                    paymentUI.groupId == groupId &&
                    paymentUI.id != payment.id &&
                    paymentUI.currency != payment.currency
                }
                
                otherPayment = otherPaymentFound
                
                // Create ViewModel with both payments using the container method
                viewModel = container.makeEditPaymentViewModel(
                    for: payment,
                    otherPayment: otherPaymentFound,
                    calendarEventDataSource: dependencies.calendarEventDataSource
                )
                
            case .failure:
                // If we can't find the other payment, just edit the single payment
                viewModel = container.makeEditPaymentViewModel(
                    for: payment,
                    calendarEventDataSource: dependencies.calendarEventDataSource
                )
            }
        } else {
            // No groupId, just edit the single payment
            let container = dependencies.paymentDependencyContainer
            viewModel = container.makeEditPaymentViewModel(
                for: payment,
                calendarEventDataSource: dependencies.calendarEventDataSource
            )
        }
    }
}

// MARK: - Extracted Form View to reduce type complexity
private struct EditPaymentFormView: View {
    @Bindable var viewModel: EditPaymentViewModel
    let dismiss: DismissAction

    var body: some View {
        Form {
            PaymentDetailsSection(
                name: $viewModel.name,
                category: $viewModel.category,
                dueDate: $viewModel.dueDate,
                showPaidToggle: true,
                isPaid: $viewModel.isPaid
            )

            // Show dual-currency section for grouped credit card payments
            if viewModel.isDualCurrencyPayment {
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

            if viewModel.hasChanges {
                Section {
                    Button("Descartar Cambios", role: .destructive) {
                        viewModel.resetChanges()
                    }
                }
            }
        }
        .navigationTitle("Editar Pago")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await viewModel.saveChanges(onSuccess: { dismiss() })
                    }
                }
                .disabled(!viewModel.isValid || !viewModel.hasChanges)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Guardando...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
}

#Preview {
    EditPaymentView(
        payment: PaymentUI(
            id: UUID(),
            name: "Sample Payment",
            amount: 100.0,
            currency: .pen,
            dueDate: Date(),
            isPaid: false,
            category: .servicios,
            eventIdentifier: nil,
            syncStatus: .synced,
            lastSyncedAt: Date(),
            groupId: nil
        )
    )
}
