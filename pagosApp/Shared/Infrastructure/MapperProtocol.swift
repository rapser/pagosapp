//
//  MapperProtocol.swift
//  pagosApp
//
//  Generic mapper protocol and registry for Clean Architecture data mapping
//  Centralizes the Data Mapper pattern to eliminate inconsistency across layers
//

import Foundation

// MARK: - Generic Mapper Protocol

/// Generic bidirectional mapper protocol following Clean Architecture patterns
protocol DataMapper {
    associatedtype Input
    associatedtype Output
    
    func map(_ input: Input) -> Output
    func mapMany(_ inputs: [Input]) -> [Output]
}

/// Default implementation for array mapping
extension DataMapper {
    func mapMany(_ inputs: [Input]) -> [Output] {
        inputs.map { map($0) }
    }
}

/// Generic bidirectional mapper protocol
protocol BidirectionalMapper: DataMapper {
    func mapReverse(_ output: Output) -> Input
    func mapManyReverse(_ outputs: [Output]) -> [Input]
}

/// Default implementation for reverse array mapping
extension BidirectionalMapper {
    func mapManyReverse(_ outputs: [Output]) -> [Input] {
        outputs.map { mapReverse($0) }
    }
}

// MARK: - Mapper Registry

/// Centralized registry providing access to all app mappers
/// Use this to avoid creating mappers in multiple places
final class MapperRegistry: @unchecked Sendable {
    static let shared = MapperRegistry()
    private init() {}
    
    // MARK: - Payment Mappers
    
    private(set) lazy var paymentUIMapper: PaymentUIMapping = PaymentUIMapper()
    private(set) lazy var paymentRemoteMapper: PaymentRemoteDTOMapping = PaymentRemoteDTOMapper()
    
    // MARK: - Reminder Mappers
    
    private(set) lazy var reminderRemoteMapper: ReminderRemoteDTOMapping = ReminderRemoteDTOMapper()
    
    // MARK: - UserProfile Mappers
    
    private(set) lazy var userProfileUIMapper: UserProfileUIMapping = UserProfileUIMapper()
    private(set) lazy var userProfileDomainMapper: UserProfileDomainMapping = UserProfileDomainMapper()
    private(set) lazy var userProfileRemoteMapper: UserProfileRemoteDTOMapping = UserProfileRemoteDTOMapper()
}

// MARK: - Mapper Protocol Compliance Tags

/// Marker protocol for domain-to-persistence mappers
protocol DomainPersistenceMapper {}

/// Marker protocol for domain-to-remote mappers
protocol DomainRemoteMapper {}

/// Marker protocol for domain-to-presentation mappers
protocol DomainPresentationMapper {}
