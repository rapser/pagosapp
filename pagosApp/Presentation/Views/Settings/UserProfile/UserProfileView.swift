//
//  UserProfileView.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//
//  LEGACY VIEW - TODO: Migrate sections to use UserProfileEntity
//  Currently uses SwiftData @Query for compatibility
//

import SwiftUI
import Supabase
import SwiftData

struct UserProfileView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var editableProfile: EditableProfile?
    @State private var showDatePicker = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var isFormValid: Bool {
        guard let editable = editableProfile else { return false }
        return !editable.fullName.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                ProfileNavigationBar(
                    isEditing: isEditing,
                    isSaving: isSaving,
                    isFormValid: isFormValid,
                    onCancel: { cancelEditing() },
                    onDismiss: { dismiss() },
                    onEdit: { startEditing() },
                    onSave: {
                        Task {
                            await saveProfile()
                        }
                    }
                )

                // Content
                ZStack {
                    Color("AppBackground").ignoresSafeArea()

                    if let profile = profile {
                        Form {
                            PersonalInformationSection(
                                profile: profile,
                                isEditing: isEditing,
                                editableProfile: $editableProfile,
                                showDatePicker: $showDatePicker
                            )

                            LocationSection(
                                profile: profile,
                                isEditing: isEditing,
                                editableProfile: $editableProfile
                            )

                            PreferencesSection(
                                profile: profile,
                                isEditing: isEditing,
                                editableProfile: $editableProfile
                            )
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    } else {
                        ProgressView("Cargando perfil...")
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Perfil actualizado", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    isEditing = false
                }
            } message: {
                Text("Tu perfil ha sido actualizado correctamente.")
            }
        }
    }

    private func startEditing() {
        // EditableProfile is from Clean Architecture, but sections expect UserProfile (SwiftData)
        // For now, just mark as editing without creating EditableProfile
        isEditing = true
    }

    private func cancelEditing() {
        editableProfile = nil
        isEditing = false
        showDatePicker = false
    }

    private func saveProfile() async {
        guard let profile = profile else { return }

        isSaving = true
        defer { isSaving = false }

        // SwiftData model updates happen directly in sections
        // Just save the context
        do {
            try modelContext.save()
            showSuccessAlert = true
            isEditing = false
            editableProfile = nil
        } catch {
            errorMessage = "Error al guardar: \(error.localizedDescription)"
        }
    }
}

#Preview {
    @Previewable @State var container = try! ModelContainer(for: UserProfile.self, Payment.self)
    let context = ModelContext(container)

    UserProfileView()
}
