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
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var showSuccessAlert = false
    @State private var showDatePicker = false
    
    // Single state for all editable fields
    @State private var editableProfile: EditableProfile?
    
    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(supabaseClient: supabaseClient, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AppBackground").edgesIgnoringSafeArea(.all)
                
                if let profile = viewModel.profile {
                    Form {
                        // Personal Information Section
                        Section(header: Text("Información Personal").foregroundColor(Color("AppTextPrimary"))) {
                            // Full Name
                            if isEditing, let binding = Binding($editableProfile) {
                                EditableTextFieldRow(
                                    icon: "person.fill",
                                    placeholder: "Nombre completo",
                                    text: binding.fullName
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "person.fill",
                                    title: "Nombre",
                                    value: profile.fullName,
                                    isOptional: false
                                )
                            }
                            
                            // Email (read-only)
                            ProfileFieldRow(
                                icon: "envelope.fill",
                                title: "Correo electrónico",
                                value: profile.email,
                                isOptional: false
                            )
                            
                            // Phone
                            if isEditing, let binding = Binding($editableProfile) {
                                EditableTextFieldRow(
                                    icon: "phone.fill",
                                    placeholder: "Teléfono",
                                    text: binding.phone,
                                    keyboardType: .phonePad
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "phone.fill",
                                    title: "Teléfono",
                                    value: profile.phone
                                )
                            }
                            
                            // Gender
                            if let binding = Binding($editableProfile) {
                                GenderPickerRow(
                                    isEditing: isEditing,
                                    selectedGender: binding.gender
                                )
                            }
                            
                            // Date of Birth
                            if let binding = Binding($editableProfile) {
                                DatePickerRow(
                                    isEditing: isEditing,
                                    selectedDate: binding.dateOfBirth,
                                    showPicker: $showDatePicker
                                )
                            }
                        }
                        
                        // Location Section
                        Section(header: Text("Ubicación").foregroundColor(Color("AppTextPrimary"))) {
                            // City
                            if isEditing, let binding = Binding($editableProfile) {
                                EditableTextFieldRow(
                                    icon: "building.2.fill",
                                    placeholder: "Ciudad",
                                    text: binding.city
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "building.2.fill",
                                    title: "Ciudad",
                                    value: profile.city
                                )
                            }
                            
                            // Country (read-only)
                            ProfileFieldRow(
                                icon: "flag.fill",
                                title: "País",
                                value: profile.country ?? "Perú",
                                isOptional: false
                            )
                        }
                        
                        // Preferences Section
                        Section(header: Text("Preferencias").foregroundColor(Color("AppTextPrimary"))) {
                            if let binding = Binding($editableProfile) {
                                CurrencyPickerRow(
                                    isEditing: isEditing,
                                    selectedCurrency: binding.preferredCurrency
                                )
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else if let errorMessage = viewModel.errorMessage {
                    ProfileErrorView(errorMessage: errorMessage) {
                        Task {
                            _ = await viewModel.fetchAndSaveProfile()
                        }
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button {
                            Task {
                                await saveProfile()
                            }
                        } label: {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Guardar")
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(viewModel.isSaving || editableProfile?.fullName.isEmpty == true)
                    } else {
                        Button {
                            startEditing()
                        } label: {
                            Text("Editar")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancelar") {
                            cancelEditing()
                        }
                        .foregroundColor(.white)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
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
        editableProfile = nil
        isEditing = false
        showDatePicker = false
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
