//
//  PaymentOperationsService 2.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for payment operations (ISP)
@MainActor
protocol PaymentOperationsService {
    func createPayment(_ payment: Payment) async throws
    func updatePayment(_ payment: Payment) async throws
    func deletePayment(_ payment: Payment) async throws
}
