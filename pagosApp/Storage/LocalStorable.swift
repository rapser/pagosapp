//
//  LocalStorable.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for entities that can be stored locally
protocol LocalStorable {
    associatedtype Identifier: Hashable
    var id: Identifier { get }
}