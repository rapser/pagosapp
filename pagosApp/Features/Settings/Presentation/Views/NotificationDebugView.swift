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
                        Text("Estado de Notificaciones")
                            .font(.headline)
                        
                        HStack {
                            Text("Autorización:")
                            Spacer()
                            Text(authorizationText)
                                .foregroundStyle(authorizationColor)
                        }
                        
                        HStack {
                            Text("Notificaciones pendientes:")
                            Spacer()
                            Text("\(viewModel.pendingCount)")
                        }
                        
                        HStack {
                            Text("- Recordatorios:")
                            Spacer()
                            Text("\(viewModel.reminderCount)")
                                .foregroundStyle(viewModel.reminderCount > 0 ? .blue : .secondary)
                        }
                        
                        HStack {
                            Text("- Pagos:")
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
                            Text("Última Acción")
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
                        Text("Prueba de Notificación")
                            .font(.headline)
                        
                        TextField("Título del recordatorio", text: $testTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        DatePicker("Fecha de vencimiento", 
                                 selection: $testDate, 
                                 displayedComponents: [.date, .hourAndMinute])
                        
                        Button("Programar Notificación de Prueba") {
                            viewModel.scheduleTestNotification(title: testTitle, dueDate: testDate)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testTitle.isEmpty)
                        
                        Button("🔄 Reescalar TODAS las Notificaciones de Recordatorios") {
                            Task {
                                await viewModel.rescheduleAllReminderNotifications()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.white)
                        .background(.orange)
                        .cornerRadius(8)

                        Button("💳 Reescalar TODAS las Notificaciones de Pagos") {
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
                            Text("Notificaciones de Recordatorios (\(viewModel.reminderCount))")
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
                            Text("Notificaciones de Pagos (\(viewModel.paymentCount))")
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
                        Button("Actualizar Estado") {
                            Task {
                                await viewModel.refreshStatus()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Ver Logs Detallados") {
                            Task {
                                await viewModel.debugPendingNotifications()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Solicitar Permisos") {
                            viewModel.requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.authorizationStatus == .authorized)
                        
                        Button("Cancelar Todas las Notificaciones") {
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
            .navigationTitle("Debug Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.refreshStatus()
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Cargando...")
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
        case .authorized: return "Autorizada"
        case .denied: return "Denegada"
        case .notDetermined: return "No determinada"
        case .provisional: return "Provisional"
        case .ephemeral: return "Efímera"
        @unknown default: return "Desconocida"
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
