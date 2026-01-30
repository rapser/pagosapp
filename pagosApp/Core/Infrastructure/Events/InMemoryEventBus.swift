//
//  InMemoryEventBus.swift
//  pagosApp
//
//  In-memory implementation of EventBus using AsyncStream
//  Clean Architecture - Infrastructure Layer
//

import Foundation

/// In-memory event bus implementation using AsyncStream
/// Thread-safe and reactive event bus for domain events
@MainActor
final class InMemoryEventBus: EventBus {
    // Storage for event continuations, keyed by event type name
    private var continuations: [String: [any Continuation]] = [:]

    // Type-erased continuation wrapper
    private protocol Continuation: AnyObject {
        func yield(_ event: any DomainEvent)
    }

    // Concrete continuation wrapper
    private final class TypedContinuation<T: DomainEvent>: Continuation {
        let continuation: AsyncStream<T>.Continuation

        init(continuation: AsyncStream<T>.Continuation) {
            self.continuation = continuation
        }

        func yield(_ event: any DomainEvent) {
            guard let typedEvent = event as? T else { return }
            continuation.yield(typedEvent)
        }
    }

    init() {}

    func publish<T: DomainEvent>(_ event: T) {
        let typeName = String(describing: T.self)

        // Yield event to all subscribers of this type
        continuations[typeName]?.forEach { continuation in
            continuation.yield(event)
        }
    }

    func subscribe<T: DomainEvent>(to eventType: T.Type) -> AsyncStream<T> {
        let typeName = String(describing: eventType)

        return AsyncStream { continuation in
            // Create typed continuation wrapper
            let wrapper = TypedContinuation(continuation: continuation)

            // Store continuation
            if continuations[typeName] == nil {
                continuations[typeName] = []
            }
            continuations[typeName]?.append(wrapper)

            // Clean up when stream terminates
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.continuations[typeName]?.removeAll { cont in
                        cont === wrapper
                    }
                    if self.continuations[typeName]?.isEmpty == true {
                        self.continuations.removeValue(forKey: typeName)
                    }
                }
            }
        }
    }
}
