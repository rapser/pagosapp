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

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }

    // MARK: - Repositories

    func makePaymentRepository() -> PaymentRepositoryProtocol {
        return PaymentRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource
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

    func makeCreatePaymentUseCase() -> CreatePaymentUseCase {
        return CreatePaymentUseCase(
            paymentRepository: makePaymentRepository()
        )
    }

    func makeUpdatePaymentUseCase() -> UpdatePaymentUseCase {
        return UpdatePaymentUseCase(
            paymentRepository: makePaymentRepository()
        )
    }

    func makeDeletePaymentUseCase() -> DeletePaymentUseCase {
        return DeletePaymentUseCase(
            paymentRepository: makePaymentRepository()
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

    func makeAddPaymentViewModel() -> AddPaymentViewModel {
        return AddPaymentViewModel(
            createPaymentUseCase: makeCreatePaymentUseCase()
        )
    }

    func makeEditPaymentViewModel(for payment: PaymentEntity) -> EditPaymentViewModel {
        return EditPaymentViewModel(
            payment: payment,
            updatePaymentUseCase: makeUpdatePaymentUseCase(),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase()
        )
    }

    func makePaymentsListViewModel() -> PaymentsListViewModel {
        return PaymentsListViewModel(
            getAllPaymentsUseCase: makeGetAllPaymentsUseCase(),
            deletePaymentUseCase: makeDeletePaymentUseCase(),
            togglePaymentStatusUseCase: makeTogglePaymentStatusUseCase()
        )
    }
}
