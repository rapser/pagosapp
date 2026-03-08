//
//  LocationSection.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import SwiftUI

struct LocationSection: View {
    let profile: UserProfile
    let isEditing: Bool
    @Binding var editableProfile: EditableProfileUI?

    var body: some View {
        Section(header: Text(L10n.Profile.sectionLocation).foregroundColor(Color("AppTextPrimary"))) {
            // City
            if isEditing, editableProfile != nil {
                EditableTextFieldRow(
                    icon: "building.2.fill",
                    placeholder: L10n.Profile.fieldCity,
                    text: Binding(
                        get: { self.editableProfile?.city ?? "" },
                        set: { self.editableProfile?.city = $0 }
                    )
                )
            } else {
                ProfileFieldRow(
                    icon: "building.2.fill",
                    title: L10n.Profile.fieldCity,
                    value: profile.city
                )
            }

            // Country (read-only)
            ProfileFieldRow(
                icon: "flag.fill",
                title: L10n.Profile.fieldCountry,
                value: profile.country ?? "Perú",
                isOptional: false
            )
        }
    }
}

#Preview("View Mode") {
    @Previewable @State var editableProfile: EditableProfileUI? = nil

    let mockProfile = UserProfileUIMapper().toDomain(UserProfileUI.mock)

    Form {
        LocationSection(
            profile: mockProfile,
            isEditing: false,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}

#Preview("Edit Mode") {
    @Previewable @State var editableProfile: EditableProfileUI? = EditableProfileUI(from: UserProfileUI.mock)

    let mockProfile = UserProfileUIMapper().toDomain(UserProfileUI.mock)

    Form {
        LocationSection(
            profile: mockProfile,
            isEditing: true,
            editableProfile: $editableProfile
        )
    }
    .scrollContentBackground(.hidden)
}
