import SwiftUI

struct CalendarPaymentsView: View {
    @Environment(AlertManager.self) private var alertManager
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: CalendarViewModel?

    private var paymentsForSelectedDate: [PaymentUI] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.paymentsForSelectedDate
    }

    private var remindersForSelectedDate: [Reminder] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.remindersForSelectedDate
    }

    private var allPayments: [PaymentUI] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.allPayments
    }

    private var allReminders: [Reminder] {
        guard let viewModel = viewModel else { return [] }
        return viewModel.allReminders
    }

    private var hasItemsForSelectedDate: Bool {
        !paymentsForSelectedDate.isEmpty || !remindersForSelectedDate.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel

                    VStack(spacing: 0) {
                        CustomCalendarView(selectedDate: $vm.selectedDate, payments: allPayments, reminders: allReminders)
                            .background(Color("AppBackground"))
                            .onChange(of: vm.selectedDate) { _, newDate in
                                Task {
                                    await vm.selectDate(newDate)
                                }
                            }

                        Divider()

                        VStack(alignment: .leading, spacing: 0) {
                            Text(L10n.Calendar.itemsFor(date: longDateFormatter.string(from: vm.selectedDate)))
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding()

                            if !hasItemsForSelectedDate {
                                ContentUnavailableView(L10n.Calendar.noItemsTitle, systemImage: "calendar.badge.exclamationmark", description: Text(L10n.Calendar.noItemsDescription))
                                    .foregroundColor(Color("AppTextSecondary"))
                            } else {
                                List {
                                    if !paymentsForSelectedDate.isEmpty {
                                        Section(L10n.Calendar.sectionPayments) {
                                            ForEach(paymentsForSelectedDate) { payment in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(payment.name).fontWeight(.semibold)
                                                        Text(L10n.Payments.categoryDisplayName(payment.category)).font(.caption).foregroundColor(Color("AppTextSecondary"))
                                                    }
                                                    Spacer()
                                                    Text("\(payment.currency.symbol) \(payment.amount, format: .number.precision(.fractionLength(2)))")
                                                        .foregroundColor(Color("AppTextPrimary"))
                                                }
                                            }
                                        }
                                    }
                                    if !remindersForSelectedDate.isEmpty {
                                        Section(L10n.Calendar.sectionReminders) {
                                            ForEach(remindersForSelectedDate) { reminder in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(reminder.title).fontWeight(.semibold)
                                                        Text(L10n.Reminders.typeDisplayName(reminder.reminderType)).font(.caption).foregroundColor(Color("AppTextSecondary"))
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                                .listStyle(.plain)
                            }
                        }
                    }
                    .navigationTitle(L10n.Calendar.title)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(L10n.Calendar.sync) {
                                syncPaymentsWithCalendar()
                            }
                            .foregroundColor(Color("AppPrimary"))
                        }
                    }
                } else {
                    ProgressView(L10n.General.loading)
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
                    title: Text(L10n.Calendar.alertSyncSuccess),
                    message: Text(message),
                    buttons: [AlertButton(title: Text(L10n.General.ok), role: .cancel) { }]
                )

            case .noPayments:
                alertManager.show(
                    title: Text(L10n.Calendar.alertNoPaymentsTitle),
                    message: Text(L10n.Calendar.alertNoPaymentsMessage),
                    buttons: [AlertButton(title: Text(L10n.General.ok), role: .cancel) { }]
                )

            case .accessDenied:
                alertManager.show(
                    title: Text(L10n.Calendar.alertAccessDenied),
                    message: Text(L10n.Calendar.alertAccessDeniedMessage),
                    buttons: [AlertButton(title: Text(L10n.General.ok), role: .cancel) { }]
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
