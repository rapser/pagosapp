//
//  ProfileNavigationBar.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import SwiftUI

struct ProfileNavigationBar: View {
    let isEditing: Bool
    let isSaving: Bool
    let isFormValid: Bool
    let onCancel: () -> Void
    let onDismiss: () -> Void
    let onEdit: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var buttonColor: Color {
        colorScheme == .dark ? .white : Color("AppPrimary")
    }

    var body: some View {
        HStack {
            // Leading button (Cancel or Close)
            if isEditing {
                Button("Cancelar") {
                    onCancel()
                }
                .foregroundColor(buttonColor)
            } else {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(buttonColor)
                }
            }

            Spacer()

            // Title
            Text("Mi Perfil")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))

            Spacer()

            // Trailing button (Edit or Save)
            if isEditing {
                Button {
                    onSave()
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(buttonColor)
                    } else {
                        Text("Guardar")
                            .foregroundColor(buttonColor)
                    }
                }
                .disabled(isSaving || !isFormValid)
            } else {
                Button {
                    onEdit()
                } label: {
                    Text("Editar")
                        .foregroundColor(buttonColor)
                }
            }
        }
        .padding()
        .background(Color("AppBackground"))
    }
}

#Preview("Light Mode - View") {
    ProfileNavigationBar(
        isEditing: false,
        isSaving: false,
        isFormValid: true,
        onCancel: {},
        onDismiss: {},
        onEdit: {},
        onSave: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode - View") {
    ProfileNavigationBar(
        isEditing: false,
        isSaving: false,
        isFormValid: true,
        onCancel: {},
        onDismiss: {},
        onEdit: {},
        onSave: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Light Mode - Editing") {
    ProfileNavigationBar(
        isEditing: true,
        isSaving: false,
        isFormValid: true,
        onCancel: {},
        onDismiss: {},
        onEdit: {},
        onSave: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Saving State") {
    ProfileNavigationBar(
        isEditing: true,
        isSaving: true,
        isFormValid: true,
        onCancel: {},
        onDismiss: {},
        onEdit: {},
        onSave: {}
    )
}
