
import SwiftUI

struct EditPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: EditPaymentViewModel?
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
                    // Get Use Cases from DI Container
                    let container = dependencies.paymentDependencyContainer
                    // Convert UI -> Domain for ViewModel
                    viewModel = container.makeEditPaymentViewModel(for: payment.toDomain())
                }
            }
        }
    }
}

// MARK: - Extracted Form View to reduce type complexity
private struct EditPaymentFormView: View {
    @Bindable var viewModel: EditPaymentViewModel
    let dismiss: DismissAction

    var body: some View {
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
            lastSyncedAt: Date()
        )
    )
}
