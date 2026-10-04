//
//  UndoableDeletion.swift
//  pagosApp
//
//  Delays a delete for a few seconds so the user can undo it.
//  Presentation pattern: the ViewModel hides the item right away and only calls
//  its delete use case when the undo window closes.
//

import Foundation
import Observation

@MainActor
@Observable
final class UndoableDeletion {
    /// Message shown in the undo banner; nil when nothing is pending.
    private(set) var message: String?

    private var commitAction: (@MainActor () async -> Void)?
    private var undoAction: (@MainActor () -> Void)?
    private var timerTask: Task<Void, Never>?
    private let window: Duration

    init(window: Duration = .seconds(4)) {
        self.window = window
    }

    /// Starts the undo window. A previous pending delete is committed first (one at a time).
    func schedule(message: String, onUndo: @escaping @MainActor () -> Void, commit: @escaping @MainActor () async -> Void) async {
        await commitPending()
        self.message = message
        undoAction = onUndo
        commitAction = commit
        timerTask = Task { [weak self, window] in
            try? await Task.sleep(for: window)
            guard !Task.isCancelled else { return }
            await self?.commitPending()
        }
    }

    func undo() {
        let action = undoAction
        reset()
        action?()
    }

    /// Runs the pending delete now (e.g. when leaving the screen or before reloading the list).
    func commitPending() async {
        let action = commitAction
        reset()
        await action?()
    }

    private func reset() {
        timerTask?.cancel()
        timerTask = nil
        message = nil
        undoAction = nil
        commitAction = nil
    }
}
