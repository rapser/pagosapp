//
//  EventBus.swift
//  pagosApp
//
//  Event bus for publishing and subscribing to domain events
//  Clean Architecture - Domain Layer
//

import Foundation

/// Event bus protocol for publishing and subscribing to domain events
/// This is a type-safe, reactive alternative to NotificationCenter
@MainActor
protocol EventBus: Sendable {
    /// Publish a domain event to all subscribers
    /// - Parameter event: The event to publish
    func publish<T: DomainEvent>(_ event: T)

    /// Subscribe to events of a specific type
    /// - Parameter eventType: The type of event to subscribe to
    /// - Returns: AsyncStream that emits events of the specified type
    func subscribe<T: DomainEvent>(to eventType: T.Type) -> AsyncStream<T>
}
