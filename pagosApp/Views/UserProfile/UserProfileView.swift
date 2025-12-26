//
//  UserProfileView.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//

import SwiftUI
import Supabase
import SwiftData

struct UserProfileView: View {
    @State private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var showSuccessAlert = false
    @State private var showDatePicker = false

    // Single state for all editable fields
    @State private var editableProfile: EditableProfile?

    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        _viewModel = State(wrappedValue: UserProfileViewModel(supabaseClient: supabaseClient, modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                ProfileNavigationBar(
                    isEditing: isEditing,
                    isSaving: viewModel.isSaving,
                    isFormValid: editableProfile?.fullName.isEmpty == false,
                    onCancel: cancelEditing,
                    onDismiss: { dismiss() },
                    onEdit: startEditing,
                    onSave: {
                        Task {
                            await saveProfile()
                        }
                    }
                )

                // Content
                ZStack {
                    Color("AppBackground").ignoresSafeArea()

                    if let profileEntity = viewModel.profile {
                        let profile = profileEntity.toModel()
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
                    } else if let errorMessage = viewModel.errorMessage {
                        ProfileErrorView(errorMessage: errorMessage) {
                            Task {
                                _ = await viewModel.fetchAndSaveProfile()
                            }
                        }
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
            .task {
                // Load from local storage (instant)
                await viewModel.loadLocalProfile()
            }
        }
    }

    // MARK: - Helper Methods

    private func startEditing() {
        guard let profile = viewModel.profile else { return }
        editableProfile = EditableProfile(from: profile)
        isEditing = true
    }

    private func cancelEditing() {
        showDatePicker = false
        editableProfile = nil
        isEditing = false
    }

    private func saveProfile() async {
        guard let edited = editableProfile else { return }

        let success = await viewModel.updateProfile(with: edited)
        if success {
            showSuccessAlert = true
            showDatePicker = false
            editableProfile = nil
        }
    }
}

#Preview {
    @Previewable @State var container = try! ModelContainer(for: UserProfile.self, Payment.self)
    let context = ModelContext(container)

    UserProfileView(
        supabaseClient: SupabaseClient(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: "dummy_key"
        ),
        modelContext: context
    )
}
