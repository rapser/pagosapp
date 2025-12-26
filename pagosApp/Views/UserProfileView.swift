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
    @Environment(\.colorScheme) var colorScheme
    @State private var isEditing = false
    @State private var showSuccessAlert = false
    @State private var showDatePicker = false

    // Single state for all editable fields
    @State private var editableProfile: EditableProfile?

    // Adaptive button color based on light/dark mode
    private var buttonColor: Color {
        colorScheme == .dark ? .white : Color("AppPrimary")
    }
    
    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        _viewModel = State(wrappedValue: UserProfileViewModel(supabaseClient: supabaseClient, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    // Leading button (Cancel or Close)
                    if isEditing {
                        Button("Cancelar") {
                            cancelEditing()
                        }
                        .foregroundColor(buttonColor)
                    } else {
                        Button {
                            dismiss()
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
                            Task {
                                await saveProfile()
                            }
                        } label: {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(buttonColor)
                            } else {
                                Text("Guardar")
                                    .foregroundColor(buttonColor)
                            }
                        }
                        .disabled(viewModel.isSaving || editableProfile?.fullName.isEmpty == true)
                    } else {
                        Button {
                            startEditing()
                        } label: {
                            Text("Editar")
                                .foregroundColor(buttonColor)
                        }
                    }
                }
                .padding()
                .background(Color("AppBackground"))

                // Content
                ZStack {
                    Color("AppBackground").ignoresSafeArea()

                    if let profile = viewModel.profile {
                        Form {
                        // Personal Information Section
                        Section(header: Text("Información Personal").foregroundColor(Color("AppTextPrimary"))) {
                            // Full Name
                            if isEditing, editableProfile != nil {
                                EditableTextFieldRow(
                                    icon: "person.fill",
                                    placeholder: "Nombre completo",
                                    text: Binding(
                                        get: { self.editableProfile?.fullName ?? "" },
                                        set: { self.editableProfile?.fullName = $0 }
                                    )
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
                            if isEditing, editableProfile != nil {
                                EditableTextFieldRow(
                                    icon: "phone.fill",
                                    placeholder: "Teléfono",
                                    text: Binding(
                                        get: { self.editableProfile?.phone ?? "" },
                                        set: { self.editableProfile?.phone = $0 }
                                    ),
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
                            if isEditing, editableProfile != nil {
                                GenderPickerRow(
                                    isEditing: isEditing,
                                    selectedGender: Binding(
                                        get: { self.editableProfile?.gender },
                                        set: { self.editableProfile?.gender = $0 }
                                    )
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "person.2.fill",
                                    title: "Género",
                                    value: profile.gender?.displayName
                                )
                            }

                            // Date of Birth
                            if isEditing, editableProfile != nil {
                                DatePickerRow(
                                    isEditing: isEditing,
                                    selectedDate: Binding(
                                        get: { self.editableProfile?.dateOfBirth },
                                        set: { self.editableProfile?.dateOfBirth = $0 }
                                    ),
                                    showPicker: $showDatePicker
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "calendar",
                                    title: "Fecha de nacimiento",
                                    value: profile.dateOfBirth?.formatted(date: .long, time: .omitted)
                                )
                            }
                        }
                        
                        // Location Section
                        Section(header: Text("Ubicación").foregroundColor(Color("AppTextPrimary"))) {
                            // City
                            if isEditing, editableProfile != nil {
                                EditableTextFieldRow(
                                    icon: "building.2.fill",
                                    placeholder: "Ciudad",
                                    text: Binding(
                                        get: { self.editableProfile?.city ?? "" },
                                        set: { self.editableProfile?.city = $0 }
                                    )
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
                            if isEditing, editableProfile != nil {
                                CurrencyPickerRow(
                                    isEditing: isEditing,
                                    selectedCurrency: Binding(
                                        get: { self.editableProfile?.preferredCurrency ?? .pen },
                                        set: { self.editableProfile?.preferredCurrency = $0 }
                                    )
                                )
                            } else {
                                ProfileFieldRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "Moneda preferida",
                                    value: profile.preferredCurrency.displayName,
                                    isOptional: false
                                )
                            }
                        }
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
