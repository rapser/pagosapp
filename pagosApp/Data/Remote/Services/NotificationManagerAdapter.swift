//
//  NotificationManagerAdapter.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

@MainActor
class NotificationManagerAdapter: NotificationService {
    private let manager: NotificationManager

    init(manager: NotificationManager) {
        self.manager = manager
    }

    convenience init() {
        self.init(manager: NotificationManager())
    }

    func scheduleNotifications(for payment: Payment) async {
        manager.scheduleNotification(for: payment)
    }

    func cancelNotifications(for payment: Payment) async {
        manager.cancelNotification(for: payment)
    }
}
