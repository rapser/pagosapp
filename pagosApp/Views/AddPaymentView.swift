import SwiftUI

struct AddPaymentView: View {
    // Entorno para poder cerrar la vista modal.
    @Environment(\.dismiss) private var dismiss
    // El modelContext nos permite interactuar con la base de datos de SwiftData.
    @Environment(\.modelContext) private var modelContext

    // Estados locales para los campos del formulario.
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var category: PaymentCategory = .recibo
    
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
                        guard let amountDouble = Double(amount) else { return }

                        let newPayment = Payment(name: name, amount: amountDouble, dueDate: dueDate, category: category)
                        
                        // 1. Insertar en SwiftData
                        modelContext.insert(newPayment)
                        // 2. Programar notificación
                        NotificationManager.shared.scheduleNotification(for: newPayment)
                        // 3. Añadir al calendario y guardar su ID
                        EventKitManager.shared.addEvent(for: newPayment) { eventID in
                            newPayment.eventIdentifier = eventID
                        }
                        dismiss() // Cerramos la vista
                    }
                    .disabled(name.isEmpty || amount.isEmpty) // El botón se deshabilita si faltan datos.
                }
            }
        }
    }
}

#Preview {
    AddPaymentView()
        .modelContainer(for: [Payment.self], inMemory: true)
}
