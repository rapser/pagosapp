//
//  AddReminderView.swift
//  pagosApp
//
//  Pantalla de alta de recordatorio. Entrada de la feature; obtiene dependencias del entorno.
//  Clean Architecture - Presentation.
//

import SwiftUI

struct AddReminderView: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        AddReminderContentWrapper()
            .environment(dependencies)
    }
}
