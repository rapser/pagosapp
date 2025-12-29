
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
                            
                            Picker("Moneda", selection: $vm.currency) {
                                Text("Soles").tag(Currency.pen)
                                Text("Dólares").tag(Currency.usd)
                            }
                            
                            HStack {
                                Text(vm.currency.symbol)
                                TextField("Monto", text: $vm.amount)
                                    .keyboardType(.decimalPad)
                            }
                            
                            DatePicker("Fecha de Vencimiento", selection: $vm.dueDate, displayedComponents: .date)
                            
                            Picker("Categoría", selection: $vm.category) {
                                ForEach(PaymentCategory.allCases) { category in
                                    Text(category.rawValue).tag(category)
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
