//
//  ErrorAlert.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import Foundation

/// Structure representing an error alert to display to the user
struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: ErrorSeverity
    let recoverySuggestion: String?

    var icon: String {
        severity.icon
    }
}
