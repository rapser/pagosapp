
import SwiftUI

struct AddPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: AddPaymentViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel

                    Form {
                        PaymentDetailsSection(
                            name: $vm.name,
                            category: $vm.category,
                            dueDate: $vm.dueDate
                        )

                        if vm.showDualCurrency {
                            DualCurrencyAmountSection(
                                amountPEN: $vm.amount,
                                amountUSD: $vm.amountUSD
                            )
                        } else {
                            SingleCurrencyAmountSection(
                                currency: $vm.currency,
                                amount: $vm.amount
                            )
                        }
                    }
                    .navigationTitle("Nuevo Pago")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
                                Task {
                                    await vm.savePayment()
                                    dismiss()
                                }
                            }
                            .disabled(!vm.isValid)
                        }
                    }
                    .disabled(vm.isLoading)
                    .overlay {
                        if vm.isLoading {
                            ProgressView("Guardando...")
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = dependencies.paymentDependencyContainer.makeAddPaymentViewModel()
                }
            }
        }
    }
}

#Preview {
    AddPaymentView()
        .modelContainer(for: [PaymentEntity.self], inMemory: true)
}
