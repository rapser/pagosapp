import SwiftUI
import SwiftData

struct EditPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: EditPaymentViewModel
    @Bindable var payment: Payment

    init(payment: Payment) {
        self.payment = payment
        // Defer initialization with correct modelContext to body
        _viewModel = StateObject(wrappedValue: EditPaymentViewModel(
            payment: payment,
            modelContext: ModelContext(try! ModelContainer(for: Payment.self))
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Pago")) {
                    TextField("Nombre del pago", text: $viewModel.name)
                    
                    Picker("Moneda", selection: $viewModel.currency) {
                        Text("Soles").tag(Currency.pen)
                        Text("Dólares").tag(Currency.usd)
                    }
                    
                    HStack {
                        Text(viewModel.currency.symbol)
                        TextField("Monto", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Fecha de Vencimiento", selection: $viewModel.dueDate, displayedComponents: .date)
                    
                    Picker("Categoría", selection: $viewModel.category) {
                        ForEach(PaymentCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Toggle(isOn: $viewModel.isPaid) {
                        Text("Pagado")
                    }
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
                        viewModel.saveChanges(onSuccess: { dismiss() })
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
}

#Preview {
    EditPaymentView(payment: Payment(name: "Sample", amount: 100, dueDate: Date(), category: .servicios, currency: .pen))
}
