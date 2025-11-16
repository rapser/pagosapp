import SwiftUI

struct AddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var category: PaymentCategory = .servicios
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

    private var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    private var amountValue: Double? {
        Double(amount)
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
                }
            }
            .navigationTitle("Nuevo Pago")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        savePayment()
                    }
                    .disabled(!isValid)
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

    private func savePayment() {
        guard isValid, let amountValue = amountValue else { return }

        isLoading = true

        let payment = Payment(
            name: name,
            amount: amountValue,
            dueDate: dueDate,
            isPaid: false,
            category: category
        )

        Task {
            do {
                try await paymentOperations.createPayment(payment)
                await MainActor.run {
                    clearForm()
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    ErrorHandler.shared.handle(PaymentError.saveFailed(error))
                }
            }
        }
    }

    private func clearForm() {
        name = ""
        amount = ""
        dueDate = Date()
        category = .servicios
    }
}

#Preview {
    AddPaymentView()
        .modelContainer(for: [Payment.self], inMemory: true)
}
