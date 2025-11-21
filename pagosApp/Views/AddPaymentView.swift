import SwiftUI
import SwiftData

struct AddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AddPaymentViewModel
    
    init(viewModel: AddPaymentViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Temporary placeholder - will create proper one in onAppear
            let container = try! ModelContainer(for: Payment.self)
            let context = ModelContext(container)
            _viewModel = StateObject(wrappedValue: AddPaymentViewModel(modelContext: context))
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Pago")) {
                    TextField("Nombre del pago", text: $viewModel.name)
                    TextField("Monto", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Fecha de Vencimiento", selection: $viewModel.dueDate, displayedComponents: .date)
                    Picker("Categoría", selection: $viewModel.category) {
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
                        viewModel.savePayment(onSuccess: { dismiss() })
                    }
                    .disabled(!viewModel.isValid)
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
    AddPaymentView()
        .modelContainer(for: [Payment.self], inMemory: true)
}
