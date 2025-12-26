//
//  RemoteTransferable.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for DTOs that can be transferred remotely
protocol RemoteTransferable: Codable {
    associatedtype Identifier: Hashable
    var id: Identifier { get }
    var userId: UUID { get }
}