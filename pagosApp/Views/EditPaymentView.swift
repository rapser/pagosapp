import SwiftUI

struct EditPaymentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var payment: Payment

    @State private var name: String
    @State private var amount: String
    @State private var dueDate: Date
    @State private var category: PaymentCategory
    @State private var isPaid: Bool
    @State private var isLoading = false

    private var paymentOperations: PaymentOperationsService {
        let syncService = SupabasePaymentSyncService(client: supabaseClient)
        let notificationService = NotificationManagerAdapter()
        let calendarService = EventKitManagerAdapter()
        return DefaultPaymentOperationsService(
            modelContext: modelContext,
            syncService: syncService,
            notificationService: notificationService,
            calendarService: calendarService
        )
    }

    init(payment: Payment) {
        self.payment = payment
        _name = State(initialValue: payment.name)
        _amount = State(initialValue: String(format: "%.2f", payment.amount))
        _dueDate = State(initialValue: payment.dueDate)
        _category = State(initialValue: payment.category)
        _isPaid = State(initialValue: payment.isPaid)
    }

    private var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    private var amountValue: Double? {
        Double(amount)
    }

    private var hasChanges: Bool {
        name != payment.name ||
        amountValue != payment.amount ||
        !Calendar.current.isDate(dueDate, inSameDayAs: payment.dueDate) ||
        category != payment.category ||
        isPaid != payment.isPaid
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Pago")) {
                    TextField("Nombre del pago", text: $name)
                    TextField("Monto", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Fecha de Vencimiento", selection: $dueDate, displayedComponents: .date)
                    Picker("Categoría", selection: $category) {
                        ForEach(PaymentCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Toggle(isOn: $isPaid) {
                        Text("Pagado")
                    }
                }

                if hasChanges {
                    Section {
                        Button("Descartar Cambios", role: .destructive) {
                            resetChanges()
                        }
                    }
                }
            }
            .navigationTitle("Editar Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .disabled(!isValid || !hasChanges)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView("Guardando...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }

    private func saveChanges() {
        guard isValid, let amountValue = amountValue, hasChanges else { return }

        isLoading = true

        payment.name = name
        payment.amount = amountValue
        payment.dueDate = dueDate
        payment.category = category
        payment.isPaid = isPaid

        Task {
            do {
                try await paymentOperations.updatePayment(payment)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    ErrorHandler.shared.handle(PaymentError.updateFailed(error))
                }
            }
        }
    }

    private func resetChanges() {
        name = payment.name
        amount = String(format: "%.2f", payment.amount)
        dueDate = payment.dueDate
        category = payment.category
        isPaid = payment.isPaid
    }
}

#Preview {
    EditPaymentView(payment: Payment(name: "Sample", amount: 100, dueDate: Date(), category: .servicios))
}
