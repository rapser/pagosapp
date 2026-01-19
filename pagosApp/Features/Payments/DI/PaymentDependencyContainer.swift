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

    func makeCreatePaymentUseCase(calendarEventDataSource: CalendarEventDataSource? = nil) -> CreatePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        return CreatePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase
        )
    }

    func makeUpdatePaymentUseCase(calendarEventDataSource: CalendarEventDataSource? = nil) -> UpdatePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        return UpdatePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase
        )
    }

    func makeDeletePaymentUseCase(calendarEventDataSource: CalendarEventDataSource? = nil) -> DeletePaymentUseCase {
        let syncCalendarUseCase = calendarEventDataSource.map { dataSource in
            makeSyncPaymentWithCalendarUseCase(calendarEventDataSource: dataSource)
        }
        return DeletePaymentUseCase(
            paymentRepository: makePaymentRepository(),
            syncCalendarUseCase: syncCalendarUseCase
        )
    }

    func makeTogglePaymentStatusUseCase() -> TogglePaymentStatusUseCase {
        return TogglePaymentStatusUseCase(
            paymentRepository: makePaymentRepository()
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

    func makeAddPaymentViewModel(calendarEventDataSource: CalendarEventDataSource? = nil) -> AddPaymentViewModel {
        return AddPaymentViewModel(
            createPaymentUseCase: makeCreatePaymentUseCase(calendarEventDataSource: calendarEventDataSource),
            mapper: uiMapper
        )
    }

    func makeEditPaymentViewModel(
        for payment: PaymentUI,
        otherPayment: PaymentUI? = nil,
        calendarEventDataSource: CalendarEventDataSource? = nil
    ) -> EditPaymentViewModel {
        return EditPaymentViewModel(
            payment: payment,
            otherPayment: otherPayment,
            updatePaymentUseCase: makeUpdatePaymentUseCase(calendarEventDataSource: calendarEventDataSource),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase(),
            mapper: uiMapper
        )
    }

    func makePaymentsListViewModel(calendarEventDataSource: CalendarEventDataSource? = nil) -> PaymentsListViewModel {
        return PaymentsListViewModel(
            getAllPaymentsUseCase: makeGetAllPaymentsUseCase(),
            deletePaymentUseCase: makeDeletePaymentUseCase(calendarEventDataSource: calendarEventDataSource),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase(),
            mapper: uiMapper
        )
    }
}
