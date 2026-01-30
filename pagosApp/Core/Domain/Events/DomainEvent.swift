//
//  DomainEvent.swift
//  pagosApp
//
//  Base protocol for all domain events
//  Clean Architecture - Domain Layer
//

import Foundation

/// Base protocol that all domain events must conform to
/// Events are immutable data structures that represent something that happened in the domain
protocol DomainEvent: Sendable {
    /// Timestamp when the event occurred
    var timestamp: Date { get }

    /// Unique identifier for this event
    var eventId: UUID { get }
}

/// Extension to provide default event ID
extension DomainEvent {
    var eventId: UUID { UUID() }
}
