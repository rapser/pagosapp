//
//  UserProfileView.swift
//  pagosApp
//
//  Clean Architecture - Uses UserProfileViewModel with Use Cases
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: UserProfileViewModel

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

                    if viewModel.isLoading {
                        ProgressView("Cargando perfil...")
                    } else if let profile = viewModel.profile {
                        // Convert to SwiftData model for UI components
                        let profileModel = UserProfileMapper.toModel(from: profile)

                        Form {
                            PersonalInformationSection(
                                profile: profileModel,
                                isEditing: viewModel.isEditing,
                                editableProfile: $viewModel.editableProfile,
                                showDatePicker: $viewModel.showDatePicker
                            )

                            LocationSection(
                                profile: profileModel,
                                isEditing: viewModel.isEditing,
                                editableProfile: $viewModel.editableProfile
                            )

                            PreferencesSection(
                                profile: profileModel,
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
            await viewModel.loadLocalProfile()
        }
    }
}

