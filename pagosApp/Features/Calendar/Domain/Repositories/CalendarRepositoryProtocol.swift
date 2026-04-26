//
//  CalendarRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for Calendar feature
//  Clean Architecture: Wraps PaymentRepository for calendar-specific queries
//

import Foundation

/// Protocol defining calendar-specific payment queries
protocol CalendarRepositoryProtocol: Sendable {
    @MainActor
    func getPayments(forDate date: Date) async -> Result<[Payment], PaymentError>

    @MainActor
    func getPayments(forMonth month: Date) async -> Result<[Payment], PaymentError>

    @MainActor
    func getAllPayments() async -> Result<[Payment], PaymentError>
}
