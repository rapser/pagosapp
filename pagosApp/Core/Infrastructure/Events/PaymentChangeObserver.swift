//
//  PaymentChangeObserver.swift
//  pagosApp
//
//  Shared observer for payment-related domain events.
//

import Foundation

@MainActor
final class PaymentChangeObserver {
    private var tasks: [Task<Void, Never>] = []

    init() {}

    func observePaymentChanges(
        eventBus: EventBus,
        action: @escaping @MainActor @Sendable () async -> Void
    ) {
        observe(eventBus: eventBus, eventType: PaymentCreatedEvent.self, action: action)
        observe(eventBus: eventBus, eventType: PaymentUpdatedEvent.self, action: action)
        observe(eventBus: eventBus, eventType: PaymentDeletedEvent.self, action: action)
        observe(eventBus: eventBus, eventType: PaymentStatusToggledEvent.self, action: action)
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }

    func observe<T: DomainEvent>(
        eventBus: EventBus,
        eventType: T.Type,
        action: @escaping @MainActor @Sendable () async -> Void
    ) {
        let task = Task { @MainActor in
            for await _ in eventBus.subscribe(to: eventType) {
                guard !Task.isCancelled else { break }
                await action()
            }
        }
        tasks.append(task)
    }
}
