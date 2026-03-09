//
//  AddReminderContentWrapper.swift
//  pagosApp
//
//  Contenedor que crea el ViewModel en .task y muestra el formulario o carga.
//  Clean Architecture - Presentation (Reminders feature).
//

import SwiftUI

struct AddReminderContentWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: AddReminderViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    AddReminderFormView(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = dependencies.reminderDependencyContainer.makeAddReminderViewModel()
        }
    }
}
