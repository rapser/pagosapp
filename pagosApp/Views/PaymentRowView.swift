import SwiftUI
import SwiftData

struct PaymentRowView: View {
    @Bindable var payment: Payment
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var eventKitManager: EventKitManager

    var body: some View {
        HStack {
            // Checkbox para marcar como pagado
            Image(systemName: payment.isPaid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(payment.isPaid ? .green : .gray)
                .font(.title2)
                .onTapGesture {
                    // Al tocar el check, cambiamos el estado.
                    // SwiftData guarda el cambio automáticamente.
                    payment.isPaid.toggle()
                    // Actualizamos la notificación y el evento del calendario.
                    notificationManager.scheduleNotification(for: payment)
                    eventKitManager.updateEvent(for: payment)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .fontWeight(.bold)
                    .strikethrough(payment.isPaid, color: .gray)
                Text(payment.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .fontWeight(.semibold)
                    .strikethrough(payment.isPaid, color: .gray)
                Text(payment.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
