//
//  UndoBannerModifier.swift
//  pagosApp
//
//  Bottom banner with an "Undo" button for UndoableDeletion.
//

import SwiftUI

struct UndoBannerModifier: ViewModifier {
    let deletion: UndoableDeletion
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = deletion.message {
                    HStack(spacing: 16) {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button(L10n.General.undo) {
                            withAnimation { deletion.undo() }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: deletion.message)
            // Don't lose the delete if the user leaves the screen or the app
            .onDisappear {
                Task { await deletion.commitPending() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    Task { await deletion.commitPending() }
                }
            }
    }
}

extension View {
    /// Shows an undo banner while `deletion` has a pending delete.
    func undoBanner(_ deletion: UndoableDeletion) -> some View {
        modifier(UndoBannerModifier(deletion: deletion))
    }
}
