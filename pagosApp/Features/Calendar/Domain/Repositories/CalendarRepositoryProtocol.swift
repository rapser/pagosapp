//
//  CalendarRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for Calendar feature
//  Clean Architecture: Wraps PaymentRepository for calendar-specific queries
//

import Foundation

/// Protocol defining calendar-specific payment queries
protocol CalendarRepositoryProtocol {
    /// Get all payments for a specific date
    func getPayments(forDate date: Date) async -> Result<[PaymentEntity], PaymentError>

    /// Get all payments for a specific month
    func getPayments(forMonth month: Date) async -> Result<[PaymentEntity], PaymentError>

    /// Get all payments (for calendar indicators)
    func getAllPayments() async -> Result<[PaymentEntity], PaymentError>
}
