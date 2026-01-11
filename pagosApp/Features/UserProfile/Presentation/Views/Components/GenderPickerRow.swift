//
//  GenderPickerRow.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct GenderPickerRow: View {
    let isEditing: Bool
    @Binding var selectedGender: UserProfile.Gender?

    private var genderBinding: Binding<UserProfile.Gender> {
        Binding(
            get: { selectedGender ?? .masculino },
            set: { selectedGender = $0 }
        )
    }

    var body: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 25)

            if isEditing {
                Picker("Género", selection: genderBinding) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .foregroundColor(Color("AppTextPrimary"))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Género")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                    Text(selectedGender?.displayName ?? "No especificado")
                        .foregroundColor(selectedGender != nil ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                }
            }
        }
    }
}
