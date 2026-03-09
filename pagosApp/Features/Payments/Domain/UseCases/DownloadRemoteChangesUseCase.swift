//
//  DownloadRemoteChangesUseCase.swift
//  pagosApp
//
//  Use Case for downloading remote payment changes
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for downloading remote payment changes and merging with local
final class DownloadRemoteChangesUseCase {
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DownloadRemoteChangesUseCase")

    init(
        syncRepository: PaymentSyncRepositoryProtocol,
        paymentRepository: PaymentRepositoryProtocol
    ) {
        self.syncRepository = syncRepository
        self.paymentRepository = paymentRepository
    }

    /// Execute download of remote changes
    /// - Returns: Result with success or sync error
    func execute() async -> Result<Void, PaymentSyncError> {
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let remotePayments = try await syncRepository.downloadPayments(userId: userId)
            let localPayments = try await paymentRepository.getAllLocalPayments()

            for remotePayment in remotePayments {
                if let existingPayment = localPayments.first(where: { $0.id == remotePayment.id }) {
                    if existingPayment.syncStatus != .modified && existingPayment.syncStatus != .local {
                        try await paymentRepository.savePayment(remotePayment)
                    }
                } else {
                    try await paymentRepository.savePayment(remotePayment)
                }
            }

            return .success(())
        } catch let error as PaymentSyncError {
            return .failure(error)
        } catch {
            logger.error("Download failed: \(error.localizedDescription)")
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}
