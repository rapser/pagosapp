import SwiftUI
import SwiftData

struct CalendarPaymentsView: View {
    @EnvironmentObject var alertManager: AlertManager
    @Environment(\.modelContext) private var modelContext
    // Obtenemos todos los pagos para poder filtrarlos por fecha.
    @Query private var payments: [Payment]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    // Propiedad computada para obtener los pagos de la fecha seleccionada.
    private var paymentsForSelectedDate: [Payment] {
        payments.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Calendar with payment indicators
                CustomCalendarView(selectedDate: $selectedDate, payments: payments)
                    .background(Color("AppBackground"))

                Divider()

                // Lista de pagos para la fecha seleccionada
                VStack(alignment: .leading, spacing: 0) {
                    Text("Pagos para \(selectedDate, formatter: longDateFormatter)")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding()

                    if paymentsForSelectedDate.isEmpty {
                        ContentUnavailableView("Sin Pagos", systemImage: "calendar.badge.exclamationmark", description: Text("No hay pagos programados para este día."))
                            .foregroundColor(Color("AppTextSecondary"))
                    } else {
                        List(paymentsForSelectedDate) { payment in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(payment.name).fontWeight(.semibold)
                                    Text(payment.category.rawValue).font(.caption).foregroundColor(Color("AppTextSecondary"))
                                }
                                Spacer()
                                Text("\(payment.currency.symbol) \(payment.amount, format: .number.precision(.fractionLength(2)))")
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Calendario")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sincronizar") {
                        syncPaymentsWithCalendar()
                    }
                    .foregroundColor(Color("AppPrimary"))
                }
            }
        }
    }
    
    private func syncPaymentsWithCalendar() {
        guard !paymentsForSelectedDate.isEmpty else {
            alertManager.show(
                title: Text("Sin Pagos"),
                message: Text("No hay pagos para sincronizar en la fecha seleccionada."),
                buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
            )
            return
        }
        
        EventKitManager.shared.requestAccess { granted in
            if granted {
                var addedCount = 0
                var updatedCount = 0
                var skippedCount = 0
                let totalPaymentsToProcess = paymentsForSelectedDate.count
                var processedCount = 0

                for payment in paymentsForSelectedDate {
                    if payment.dueDate >= Date() {
                        if payment.eventIdentifier == nil {
                            // Add new event if not already synced
                            EventKitManager.shared.addEvent(for: payment) { eventID in
                                if let eventID = eventID {
                                    payment.eventIdentifier = eventID
                                    addedCount += 1
                                }
                                processedCount += 1
                                if processedCount == totalPaymentsToProcess {
                                    showSyncCompletionAlert(added: addedCount, updated: updatedCount, skipped: skippedCount)
                                }
                            }
                        } else {
                            // Update existing event
                            EventKitManager.shared.updateEvent(for: payment)
                            updatedCount += 1
                            processedCount += 1
                            if processedCount == totalPaymentsToProcess {
                                showSyncCompletionAlert(added: addedCount, updated: updatedCount, skipped: skippedCount)
                            }
                        }
                    } else {
                        skippedCount += 1
                        processedCount += 1
                        if processedCount == totalPaymentsToProcess {
                            showSyncCompletionAlert(added: addedCount, updated: updatedCount, skipped: skippedCount)
                        }
                    }
                }
            } else {
                alertManager.show(
                    title: Text("Permiso Denegado"),
                    message: Text("Necesitamos acceso a tu calendario para sincronizar los pagos."),
                    buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
                )
            }
        }
    }
    
    private func showSyncCompletionAlert(added: Int, updated: Int, skipped: Int) {
        var message = ""
        let totalSynced = added + updated
        
        if totalSynced > 0 {
            message += "Se han sincronizado \(totalSynced) pagos con tu calendario.\n"
        }
        if skipped > 0 {
            message += "Se han omitido \(skipped) pagos vencidos o ya sincronizados.\n"
        }
        
        alertManager.show(
            title: Text("Sincronización Completa"),
            message: Text(message.trimmingCharacters(in: .whitespacesAndNewlines)),
            buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
        )
    }
}

// Formateador de fecha para el título de la lista.
private let longDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.locale = Locale(identifier: "es_ES")
    return formatter
}()

#Preview {
    CalendarPaymentsView()
        .modelContainer(for: [Payment.self], inMemory: true)
        .environmentObject(AlertManager())
}
