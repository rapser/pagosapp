//
//  NotificationDebugView.swift
//  pagosApp
//
//  Enhanced debug view for testing notification functionality with proper architecture
//  Clean Architecture - Presentation Layer
//

import SwiftUI
import UserNotifications

struct NotificationDebugView: View {
    @State private var viewModel: NotificationDebugViewModel
    @State private var testTitle = "Test Reminder"
    @State private var testDate = Date()

    init(viewModel: NotificationDebugViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.Debug.Notifications.statusTitle)
                            .font(.headline)

                        HStack {
                            Text(L10n.Debug.Notifications.authorization)
                            Spacer()
                            Text(authorizationText)
                                .foregroundStyle(authorizationColor)
                        }

                        HStack {
                            Text(L10n.Debug.Notifications.pending)
                            Spacer()
                            Text("\(viewModel.pendingCount)")
                        }

                        HStack {
                            Text(L10n.Debug.Notifications.subReminders)
                            Spacer()
                            Text("\(viewModel.reminderCount)")
                                .foregroundStyle(viewModel.reminderCount > 0 ? .blue : .secondary)
                        }

                        HStack {
                            Text(L10n.Debug.Notifications.subPayments)
                            Spacer()
                            Text("\(viewModel.paymentCount)")
                                .foregroundStyle(viewModel.paymentCount > 0 ? .green : .secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Last action message
                    if !viewModel.lastActionMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Debug.Notifications.lastAction)
                                .font(.headline)
                            Text(viewModel.lastActionMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemYellow).opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Test section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.Debug.Notifications.testSectionTitle)
                            .font(.headline)

                        TextField(L10n.Debug.Notifications.reminderTitlePlaceholder, text: $testTitle)
                            .textFieldStyle(.roundedBorder)

                        DatePicker(
                            L10n.Debug.Notifications.dueDateLabel,
                            selection: $testDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        Button(L10n.Debug.Notifications.scheduleTest) {
                            viewModel.scheduleTestNotification(title: testTitle, dueDate: testDate)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testTitle.isEmpty)

                        Button(L10n.Debug.Notifications.rescheduleAllReminders) {
                            Task {
                                await viewModel.rescheduleAllReminderNotifications()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.white)
                        .background(.orange)
                        .cornerRadius(8)

                        Button(L10n.Debug.Notifications.rescheduleAllPayments) {
                            Task {
                                await viewModel.rescheduleAllPaymentNotifications()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.white)
                        .background(.green)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Reminder notifications details
                    if !viewModel.reminderNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Debug.Notifications.remindersListTitle(viewModel.reminderCount))
                                .font(.headline)

                            ForEach(viewModel.reminderNotifications, id: \.self) { notification in
                                Text("• \(notification)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Payment notifications details
                    if !viewModel.paymentNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Debug.Notifications.paymentsListTitle(viewModel.paymentCount))
                                .font(.headline)

                            ForEach(viewModel.paymentNotifications, id: \.self) { notification in
                                Text("• \(notification)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Actions section
                    VStack(spacing: 12) {
                        Button(L10n.Debug.Notifications.refresh) {
                            Task {
                                await viewModel.refreshStatus()
                            }
                        }
                        .buttonStyle(.bordered)

                        Button(L10n.Debug.Notifications.viewLogs) {
                            Task {
                                await viewModel.debugPendingNotifications()
                            }
                        }
                        .buttonStyle(.bordered)

                        Button(L10n.Debug.Notifications.requestPermission) {
                            viewModel.requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.authorizationStatus == .authorized)

                        Button(L10n.Debug.Notifications.cancelAll) {
                            Task {
                                await viewModel.cancelAllNotifications()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.red)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle(L10n.Debug.Notifications.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.refreshStatus()
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView {
                        Text(L10n.General.loading)
                    }
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var authorizationText: String {
        switch viewModel.authorizationStatus {
        case .authorized: return L10n.Debug.Notifications.authAuthorized
        case .denied: return L10n.Debug.Notifications.authDenied
        case .notDetermined: return L10n.Debug.Notifications.authNotDetermined
        case .provisional: return L10n.Debug.Notifications.authProvisional
        case .ephemeral: return L10n.Debug.Notifications.authEphemeral
        @unknown default: return L10n.Debug.Notifications.authUnknown
        }
    }

    private var authorizationColor: Color {
        switch viewModel.authorizationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional: return .blue
        case .ephemeral: return .blue
        @unknown default: return .gray
        }
    }
}

#Preview {
    let mockNotificationDataSource = UserNotificationsDataSource()
    let mockContainer = AppDependencies.mock()
    let mockViewModel = NotificationDebugViewModel(
        notificationDataSource: mockNotificationDataSource,
        getAllRemindersUseCase: mockContainer.reminderDependencyContainer.makeGetAllRemindersUseCase(),
        rescheduleNotificationsUseCase: mockContainer.reminderDependencyContainer.makeRescheduleReminderNotificationsUseCase(),
        getAllPaymentsUseCase: mockContainer.paymentDependencyContainer.makeGetAllPaymentsUseCase(),
        schedulePaymentNotificationsUseCase: mockContainer.paymentDependencyContainer.makeSchedulePaymentNotificationsUseCase(notificationDataSource: mockNotificationDataSource)
    )
    NotificationDebugView(viewModel: mockViewModel)
}
