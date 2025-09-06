import SwiftUI

struct EditPaymentView: View {
    @Environment(\.dismiss) var dismiss
    // @Bindable nos permite enlazar los campos del formulario directamente
    // a las propiedades del objeto 'payment'. Los cambios se guardan automáticamente.
    @Bindable var payment: Payment

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Pago")) {
                    TextField("Nombre del pago", text: $payment.name)
                    // Para el monto, necesitamos un formateador que convierta entre Double y String.
                    TextField("Monto", value: $payment.amount, format: .number)
                        .keyboardType(.decimalPad)
                    DatePicker("Fecha de Vencimiento", selection: $payment.dueDate, displayedComponents: .date)
                    Picker("Categoría", selection: $payment.category) {
                        ForEach(PaymentCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Toggle(isOn: $payment.isPaid) {
                        Text("Pagado")
                    }
                }
            }
            .navigationTitle("Editar Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hecho") {
                        // Al editar, re-programamos la notificación por si la fecha cambió.
                        NotificationManager.shared.scheduleNotification(for: payment)
                        // Y también actualizamos el evento en el calendario.
                        EventKitManager.shared.updateEvent(for: payment)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditPaymentView(payment: Payment(name: "Sample", amount: 100, dueDate: Date(), category: .recibo))
}