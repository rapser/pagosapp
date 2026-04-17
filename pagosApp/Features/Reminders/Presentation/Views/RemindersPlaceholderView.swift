//
//  RemindersPlaceholderView.swift
//  pagosApp
//
//  Placeholder for Recordatorios tab until full RemindersListView is implemented.
//

import SwiftUI

/// Temporary view for the Recordatorios tab. Replaced by RemindersListView when the feature is complete.
struct RemindersPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                L10n.Tab.reminders,
                systemImage: "bell.badge",
                description: Text(L10n.Reminders.placeholderComingSoon)
            )
            .navigationTitle(L10n.Tab.reminders)
        }
    }
}
