//
//  PaymentDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for Payment module
//  Clean Architecture - DI Layer
//

import Foundation
import SwiftData
import Supabase

/// Dependency Injection container for Payment feature
@MainActor
final class PaymentDependencyContainer {
    private let supabaseClient: SupabaseClient
    private let modelContext: ModelContext

    // Lazy-loaded data sources
    private lazy var remoteDataSource: PaymentRemoteDataSource = {
        PaymentSupabaseDataSource(client: supabaseClient)
    }()

    private lazy var localDataSource: PaymentLocalDataSource = {
        PaymentSwiftDataDataSource(modelContext: modelContext)
    }()

    // Mappers
    private let remoteDTOMapper: PaymentRemoteDTOMapping = PaymentRemoteDTOMapper()
    private let uiMapper: PaymentUIMapping = PaymentUIMapper()

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }

    // MARK: - Mappers (Helper methods)

    /// Map Domain Payment models to UI Payment models
    /// - Parameter payments: Array of domain Payment models
    /// - Returns: Array of PaymentUI models
    func mapToUI(_ payments: [Payment]) -> [PaymentUI] {
        return uiMapper.toUI(payments)
    }

    /// Map single Domain Payment model to UI Payment model
    /// - Parameter payment: Domain Payment model
    /// - Returns: PaymentUI model
    func mapToUI(_ payment: Payment) -> PaymentUI {
        return uiMapper.toUI(payment)
    }

    // MARK: - Repositories

    func makePaymentRepository() -> PaymentRepositoryProtocol {
        return PaymentRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            remoteDTOMapper: remoteDTOMapper
        )
    }

    func makePaymentSyncRepository() -> PaymentSyncRepositoryProtocol {
        return PaymentSyncRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            supabaseClient: supabaseClient
        )
    }

    // MARK: - Use Cases (CRUD)

    func makeCreatePaymentUseCase(
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> CreatePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        let scheduleNotificationsUseCase = notificationDataSource.map { dataSource in
            makeSchedulePaymentNotificationsUseCase(notificationDataSource: dataSource)
        }
        return CreatePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase,
            scheduleNotificationsUseCase: scheduleNotificationsUseCase
        )
    }

    func makeUpdatePaymentUseCase(
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> UpdatePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        let scheduleNotificationsUseCase = notificationDataSource.map { dataSource in
            makeSchedulePaymentNotificationsUseCase(notificationDataSource: dataSource)
        }
        return UpdatePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase,
            scheduleNotificationsUseCase: scheduleNotificationsUseCase
        )
    }

    func makeDeletePaymentUseCase(
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> DeletePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        let scheduleNotificationsUseCase = notificationDataSource.map { dataSource in
            makeSchedulePaymentNotificationsUseCase(notificationDataSource: dataSource)
        }
        return DeletePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase,
            scheduleNotificationsUseCase: scheduleNotificationsUseCase
        )
    }

    /// Create TogglePaymentStatusUseCase with optional notification support
    /// - Parameter notificationDataSource: Optional notification data source for scheduling notifications
    /// - Returns: Configured TogglePaymentStatusUseCase
    func makeTogglePaymentStatusUseCase(notificationDataSource: NotificationDataSource? = nil) -> TogglePaymentStatusUseCase {
        let scheduleNotificationsUseCase = notificationDataSource.map { dataSource in
            makeSchedulePaymentNotificationsUseCase(notificationDataSource: dataSource)
        }
        return TogglePaymentStatusUseCase(
            paymentRepository: makePaymentRepository(),
            scheduleNotificationsUseCase: scheduleNotificationsUseCase
        )
    }

    func makeGetAllPaymentsUseCase() -> GetAllPaymentsUseCase {
        return GetAllPaymentsUseCase(
            paymentRepository: makePaymentRepository()
        )
    }

    func makeGetPaymentUseCase() -> GetPaymentUseCase {
        return GetPaymentUseCase(
            paymentRepository: makePaymentRepository()
        )
    }

    func makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: CalendarEventDataSource) -> SyncPaymentWithCalendarUseCase {
        return SyncPaymentWithCalendarUseCase(
            calendarEventDataSource: calendarEventDataSource,
            paymentRepository: makePaymentRepository()
        )
    }

    func makeSchedulePaymentNotificationsUseCase(notificationDataSource: NotificationDataSource) -> SchedulePaymentNotificationsUseCase {
        return SchedulePaymentNotificationsUseCase(notificationDataSource: notificationDataSource)
    }

    // MARK: - Use Cases (Sync)

    func makeUploadLocalChangesUseCase() -> UploadLocalChangesUseCase {
        return UploadLocalChangesUseCase(
            syncRepository: makePaymentSyncRepository()
        )
    }

    func makeDownloadRemoteChangesUseCase() -> DownloadRemoteChangesUseCase {
        return DownloadRemoteChangesUseCase(
            syncRepository: makePaymentSyncRepository(),
            paymentRepository: makePaymentRepository()
        )
    }

    func makeSyncPaymentsUseCase() -> SyncPaymentsUseCase {
        return SyncPaymentsUseCase(
            uploadUseCase: makeUploadLocalChangesUseCase(),
            downloadUseCase: makeDownloadRemoteChangesUseCase()
        )
    }

    func makeGetPendingSyncCountUseCase() -> GetPendingSyncCountUseCase {
        return GetPendingSyncCountUseCase(
            syncRepository: makePaymentSyncRepository()
        )
    }

    // MARK: - Coordinators

    func makePaymentSyncCoordinator() -> PaymentSyncCoordinator {
        return PaymentSyncCoordinator(
            syncPaymentsUseCase: makeSyncPaymentsUseCase(),
            getPendingSyncCountUseCase: makeGetPendingSyncCountUseCase(),
            uploadLocalChangesUseCase: makeUploadLocalChangesUseCase(),
            downloadRemoteChangesUseCase: makeDownloadRemoteChangesUseCase(),
            paymentRepository: makePaymentRepository(),
            syncRepository: makePaymentSyncRepository()
        )
    }

    // MARK: - ViewModels

    func makeAddPaymentViewModel(
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> AddPaymentViewModel {
        return AddPaymentViewModel(
            createPaymentUseCase: makeCreatePaymentUseCase(
                calendarEventDataSource: calendarEventDataSource,
                notificationDataSource: notificationDataSource
            ),
            mapper: uiMapper
        )
    }

    func makeEditPaymentViewModel(
        for payment: PaymentUI,
        otherPayment: PaymentUI? = nil,
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> EditPaymentViewModel {
        return EditPaymentViewModel(
            payment: payment,
            otherPayment: otherPayment,
            updatePaymentUseCase: makeUpdatePaymentUseCase(
                calendarEventDataSource: calendarEventDataSource,
                notificationDataSource: notificationDataSource
            ),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase(notificationDataSource: notificationDataSource),
            mapper: uiMapper
        )
    }

    func makePaymentsListViewModel(
        calendarEventDataSource: CalendarEventDataSource? = nil,
        notificationDataSource: NotificationDataSource? = nil
    ) -> PaymentsListViewModel {
        let scheduleNotificationsUseCase = notificationDataSource.map { dataSource in
            makeSchedulePaymentNotificationsUseCase(notificationDataSource: dataSource)
        }
        return PaymentsListViewModel(
            getAllPaymentsUseCase: makeGetAllPaymentsUseCase(),
            deletePaymentUseCase: makeDeletePaymentUseCase(
                calendarEventDataSource: calendarEventDataSource,
                notificationDataSource: notificationDataSource
            ),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase(notificationDataSource: notificationDataSource),
            scheduleNotificationsUseCase: scheduleNotificationsUseCase,
            mapper: uiMapper
        )
    }
}
