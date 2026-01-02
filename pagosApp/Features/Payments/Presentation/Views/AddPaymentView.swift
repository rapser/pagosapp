
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
                        Section(header: Text("Detalles del Pago")) {
                            TextField("Nombre del pago", text: $vm.name)

                            Picker("Categoría", selection: $vm.category) {
                                ForEach(PaymentCategory.allCases) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }

                            DatePicker("Fecha de Vencimiento", selection: $vm.dueDate, displayedComponents: .date)
                        }

                        Section(header: Text("Montos")) {
                            if vm.showDualCurrency {
                                // Dual-currency fields for credit cards
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Tarjeta Bimoneda")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    // PEN Card
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Soles (S/)", systemImage: "banknote")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        TextField("0.00", text: $vm.amount)
                                            .keyboardType(.decimalPad)
                                            .font(.title3)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }

                                    // USD Card
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Dólares ($)", systemImage: "dollarsign.circle")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        TextField("0.00", text: $vm.amountUSD)
                                            .keyboardType(.decimalPad)
                                            .font(.title3)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }

                                    Text("💡 Ingresa al menos un monto")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                // Single currency for other categories
                                Picker("Moneda", selection: $vm.currency) {
                                    Text("Soles").tag(Currency.pen)
                                    Text("Dólares").tag(Currency.usd)
                                }

                                HStack {
                                    Text(vm.currency.symbol)
                                    TextField("Monto", text: $vm.amount)
                                        .keyboardType(.decimalPad)
                                }
                            }
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
