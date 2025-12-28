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

    init(supabaseClient: SupabaseClient,
         modelContext: ModelContext) {
        _viewModel = State(wrappedValue: UserProfileViewModel(supabaseClient: supabaseClient, modelContext: modelContext))
    }

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

                    if let profile = viewModel.profileModel {
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
            .alert("Perfil actualizado", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {
                    viewModel.isEditing = false
                }
            } message: {
                Text("Tu perfil ha sido actualizado correctamente.")
            }
            .task {
                await viewModel.loadLocalProfile()
            }
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
