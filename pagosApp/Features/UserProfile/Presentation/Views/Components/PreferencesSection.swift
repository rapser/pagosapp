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
    @Binding var editableProfile: EditableProfile?

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
    @Previewable @State var editableProfile: EditableProfile? = nil

    Form {
        PreferencesSection(
            profile: .mock,
            isEditing: false,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode - PEN") {
    @Previewable @State var editableProfile: EditableProfile? = EditableProfile(from: .mock)

    Form {
        PreferencesSection(
            profile: .mock,
            isEditing: true,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode - USD") {
    @Previewable @State var editableProfile: EditableProfile? = EditableProfile(from: .mockMinimal)

    Form {
        PreferencesSection(
            profile: .mockMinimal,
            isEditing: true,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}
