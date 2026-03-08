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
                            L10n.Profile.noProfileTitle,
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text(L10n.Profile.noProfileDescription)
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .alert(L10n.Profile.updatedTitle, isPresented: $viewModel.showSuccessAlert) {
                Button(L10n.General.ok, role: .cancel) {
                    viewModel.isEditing = false
                }
            } message: {
                Text(L10n.Profile.updatedMessage)
            }
            .errorAlert(
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                message: viewModel.errorMessage
            )
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

