import SwiftUI

struct CalendarPaymentsView: View {
    @Environment(AlertManager.self) private var alertManager
    @Environment(EventKitManager.self) private var eventKitManager
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: CalendarViewModel?

    private var paymentsForSelectedDate: [Payment] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.paymentsForSelectedDate.map { PaymentMapper.toModel(from: $0) }
    }

    private var allPayments: [Payment] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.allPayments.map { PaymentMapper.toModel(from: $0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel

                    VStack(spacing: 0) {
                        CustomCalendarView(selectedDate: $vm.selectedDate, payments: allPayments)
                            .background(Color("AppBackground"))
                            .onChange(of: vm.selectedDate) { _, newDate in
                                Task {
                                    await vm.selectDate(newDate)
                                }
                            }

                        Divider()

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Pagos para \(vm.selectedDate, formatter: longDateFormatter)")
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
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.calendarDependencyContainer.makeCalendarViewModel()
                Task {
                    await viewModel?.refresh()
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
        
        eventKitManager.requestAccess { granted in
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
                            eventKitManager.addEvent(for: payment) { eventID in
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
                            eventKitManager.updateEvent(for: payment)
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
        .environment(AlertManager())
}
