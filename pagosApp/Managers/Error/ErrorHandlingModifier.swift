//
//  ErrorHandlingModifier.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import SwiftUI
import OSLog
import Observation

struct ErrorHandlingModifier: ViewModifier {
    @Environment(ErrorHandler.self) private var errorHandler

    func body(content: Content) -> some View {
        @Bindable var handler = errorHandler
        
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $handler.showError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK", role: .cancel) {
                    errorHandler.showError = false
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(error.icon) \(error.message)")

                    if let suggestion = error.recoverySuggestion {
                        Text("\n💡 \(suggestion)")
                            .font(.caption)
                    }
                }
            }
    }
}
