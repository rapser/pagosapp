//
//  UserFacingError.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for errors that can be displayed to users
protocol UserFacingError: LocalizedError {
    var title: String { get }
    var recoverySuggestion: String? { get }
    var severity: ErrorSeverity { get }
}
