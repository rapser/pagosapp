//
//  EventKitManagerAdapter.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

class EventKitManagerAdapter: CalendarService {
    private let manager: EventKitManager

    init(manager: EventKitManager) {
        self.manager = manager
    }
    
    @MainActor
    convenience init() {
        // For convenience init, create a new instance with its own ErrorHandler
        // Ideally, pass EventKitManager via DI from AppDependencies
        self.init(manager: EventKitManager(errorHandler: ErrorHandler()))
    }

    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) async {
        manager.addEvent(for: payment, completion: completion)
    }

    func updateEvent(for payment: Payment) async {
        manager.updateEvent(for: payment)
    }

    func removeEvent(for payment: Payment) async {
        manager.removeEvent(for: payment)
    }
}
