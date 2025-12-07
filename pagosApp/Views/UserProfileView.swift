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
    
    // Editable fields
    @State private var editedFullName = ""
    @State private var editedPhone = ""
    @State private var editedCity = ""
    @State private var editedDateOfBirth: Date?
    @State private var editedGender: UserProfile.Gender?
    @State private var editedCurrency: Currency = .pen
    @State private var showDatePicker = false
    
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
                            if isEditing {
                                EditableTextFieldRow(
                                    icon: "person.fill",
                                    placeholder: "Nombre completo",
                                    text: $editedFullName
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
                            if isEditing {
                                EditableTextFieldRow(
                                    icon: "phone.fill",
                                    placeholder: "Teléfono",
                                    text: $editedPhone,
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
                            GenderPickerRow(
                                isEditing: isEditing,
                                selectedGender: $editedGender
                            )
                            
                            // Date of Birth
                            DatePickerRow(
                                isEditing: isEditing,
                                selectedDate: $editedDateOfBirth,
                                showPicker: $showDatePicker
                            )
                        }
                        
                        // Location Section
                        Section(header: Text("Ubicación").foregroundColor(Color("AppTextPrimary"))) {
                            // City
                            if isEditing {
                                EditableTextFieldRow(
                                    icon: "building.2.fill",
                                    placeholder: "Ciudad",
                                    text: $editedCity
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
                            CurrencyPickerRow(
                                isEditing: isEditing,
                                selectedCurrency: $editedCurrency
                            )
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
                        .disabled(viewModel.isSaving || editedFullName.isEmpty)
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
            .onAppear {
                // Load from local storage (instant)
                viewModel.loadLocalProfile()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startEditing() {
        guard let profile = viewModel.profile else { return }
        editedFullName = profile.fullName
        editedPhone = profile.phone ?? ""
        editedCity = profile.city ?? ""
        editedDateOfBirth = profile.dateOfBirth
        editedGender = profile.gender
        editedCurrency = profile.preferredCurrency
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        showDatePicker = false
    }
    
    private func saveProfile() async {
        guard let profile = viewModel.profile else { return }
        
        // Update profile with edited values
        profile.fullName = editedFullName
        profile.phone = editedPhone.isEmpty ? nil : editedPhone
        profile.city = editedCity.isEmpty ? nil : editedCity
        profile.dateOfBirth = editedDateOfBirth
        profile.gender = editedGender
        profile.preferredCurrency = editedCurrency
        
        let success = await viewModel.updateProfile(profile)
        if success {
            showSuccessAlert = true
            showDatePicker = false
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
