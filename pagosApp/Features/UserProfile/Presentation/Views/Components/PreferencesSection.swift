//
//  PreferencesSection.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import SwiftUI

struct PreferencesSection: View {
    let profile: UserProfile
    let isEditing: Bool
    @Binding var editableProfile: EditableProfileUI?

    var body: some View {
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
}

#Preview("View Mode") {
    @Previewable @State var editableProfile: EditableProfileUI? = nil

    let mockProfile = UserProfileUIMapper().toDomain(UserProfileUI.mock)

    Form {
        PreferencesSection(
            profile: mockProfile,
            isEditing: false,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode - PEN") {
    @Previewable @State var editableProfile: EditableProfileUI? = EditableProfileUI(from: UserProfileUI.mock)

    let mockProfile = UserProfileUIMapper().toDomain(UserProfileUI.mock)

    Form {
        PreferencesSection(
            profile: mockProfile,
            isEditing: true,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode - USD") {
    @Previewable @State var editableProfile: EditableProfileUI? = EditableProfileUI(from: UserProfileUI.mockMinimal)

    let mockProfile = UserProfileUIMapper().toDomain(UserProfileUI.mockMinimal)

    Form {
        PreferencesSection(
            profile: mockProfile,
            isEditing: true,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}
