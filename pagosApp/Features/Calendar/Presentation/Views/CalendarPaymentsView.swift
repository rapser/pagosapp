import SwiftUI

struct CalendarPaymentsView: View {
    @Environment(AlertManager.self) private var alertManager
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: CalendarViewModel?

    private var paymentsForSelectedDate: [PaymentUI] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.paymentsForSelectedDate
    }

    private var allPayments: [PaymentUI] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.allPayments
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
        .task {
            // Modern iOS 18 pattern: use .task for async initialization
            guard viewModel == nil else { return }

            viewModel = dependencies.calendarDependencyContainer.makeCalendarViewModel()
            await viewModel?.refresh()
        }
    }

    private func syncPaymentsWithCalendar() {
        guard let viewModel = viewModel else { return }

        viewModel.syncPaymentsWithCalendar { result in
            switch result {
            case .success(let added, let updated, let skipped):
                let message = """
                Sincronización completada:
                • \(added) eventos añadidos
                • \(updated) eventos actualizados
                • \(skipped) eventos omitidos (fechas pasadas)
                """

                alertManager.show(
                    title: Text("Sincronización Exitosa"),
                    message: Text(message),
                    buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
                )

            case .noPayments:
                alertManager.show(
                    title: Text("Sin Pagos"),
                    message: Text("No hay pagos para sincronizar en la fecha seleccionada."),
                    buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
                )

            case .accessDenied:
                alertManager.show(
                    title: Text("Acceso Denegado"),
                    message: Text("Por favor, habilita el acceso al calendario en Ajustes."),
                    buttons: [AlertButton(title: Text("Aceptar"), role: .cancel) { }]
                )
            }
        }
    }
}

private let longDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()
