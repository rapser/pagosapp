//
//  NotificationService.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for notification service (ISP + DIP)
@MainActor
protocol NotificationService {
    func scheduleNotifications(for payment: Payment) async
    func cancelNotifications(for payment: Payment) async
}
