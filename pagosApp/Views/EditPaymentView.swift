import SwiftUI
import SwiftData

struct EditPaymentView: View {    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EditPaymentViewModel?
    @Bindable var payment: Payment

    init(payment: Payment) {
        self.payment = payment
    }

    var body: some View {
        NavigationView {
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
                            
                            Toggle(isOn: $vm.isPaid) {
                                Text("Pagado")
                            }
                        }
                        
                        if vm.hasChanges {
                            Section {
                                Button("Descartar Cambios", role: .destructive) {
                                    vm.resetChanges()
                                }
                            }
                        }
                    }
                    .navigationTitle("Editar Pago")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
                                vm.saveChanges(onSuccess: { dismiss() })
                            }
                            .disabled(!vm.isValid || !vm.hasChanges)
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
                    viewModel = EditPaymentViewModel(payment: payment, modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    EditPaymentView(payment: Payment(name: "Sample", amount: 100, dueDate: Date(), category: .servicios, currency: .pen))
}
