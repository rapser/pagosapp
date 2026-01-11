//
//  UserProfileView.swift
//  pagosApp
//
//  Clean Architecture - Uses UserProfileViewModel with Use Cases
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State var viewModel: UserProfileViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                ProfileNavigationBar(
                    isEditing: viewModel.isEditing,
                    isSaving: viewModel.isSaving,
                    isFormValid: viewModel.isFormValid,
                    onCancel: { viewModel.cancelEditing() },
                    onDismiss: { dismiss() },
                    onEdit: { viewModel.startEditing() },
                    onSave: {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }
                )

                // Content
                ZStack {
                    Color("AppBackground").ignoresSafeArea()

                    if let profileUI = viewModel.profile {
                        // Convert UI model to Domain for components
                        let profile = UserProfileUIMapper().toDomain(profileUI)

                        Form {
                            PersonalInformationSection(
                                profile: profile,
                                isEditing: viewModel.isEditing,
                                editableProfile: $viewModel.editableProfile,
                                showDatePicker: $viewModel.showDatePicker
                            )

                            LocationSection(
                                profile: profile,
                                isEditing: viewModel.isEditing,
                                editableProfile: $viewModel.editableProfile
                            )

                            PreferencesSection(
                                profile: profile,
                                isEditing: viewModel.isEditing,
                                editableProfile: $viewModel.editableProfile
                            )
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    } else {
                        ContentUnavailableView(
                            "Sin Perfil",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("No se encontró información del perfil.")
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Perfil actualizado", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {
                    viewModel.isEditing = false
                }
            } message: {
                Text("Tu perfil ha sido actualizado correctamente.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            // Load profile from local SwiftData (fast - no loader needed)
            await viewModel.loadLocalProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserProfileDidUpdate"))) { _ in
            // Reload profile when it's updated (e.g., after login or edit)
            Task {
                await viewModel.loadLocalProfile()
            }
        }
    }
}

