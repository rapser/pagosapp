//
//  PersonalInformationSection.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import SwiftUI

struct PersonalInformationSection: View {
    let profile: UserProfile
    let isEditing: Bool
    @Binding var editableProfile: EditableProfileUI?
    @Binding var showDatePicker: Bool

    var body: some View {
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
    }
}

#Preview("View Mode") {
    @Previewable @State var editableProfile: EditableProfileUI? = nil
    @Previewable @State var showDatePicker = false

    Form {
        PersonalInformationSection(
            profile: .mock,
            isEditing: false,
            editableProfile: $editableProfile,
            showDatePicker: $showDatePicker
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode") {
    @Previewable @State var editableProfile: EditableProfileUI? = EditableProfileUI(from: .mock)
    @Previewable @State var showDatePicker = false

    Form {
        PersonalInformationSection(
            profile: .mock,
            isEditing: true,
            editableProfile: $editableProfile,
            showDatePicker: $showDatePicker
        )
    }
    .scrollContentBackground(.hidden)
}
