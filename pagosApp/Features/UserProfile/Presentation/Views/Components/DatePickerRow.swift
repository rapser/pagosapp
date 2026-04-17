//
//  DatePickerRow.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct DatePickerRow: View {
    let isEditing: Bool
    @Binding var selectedDate: Date?
    @Binding var showPicker: Bool

    private var dateBinding: Binding<Date> {
        Binding(
            get: { selectedDate ?? Date() },
            set: { selectedDate = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color("AppPrimary"))
                    .frame(width: 25)

                if isEditing {
                    Button {
                        showPicker.toggle()
                    } label: {
                        HStack {
                            Text(L10n.Profile.fieldBirthDate)
                                .foregroundColor(Color("AppTextPrimary"))
                            Spacer()
                            if let date = selectedDate {
                                Text(date, format: .dateTime.day().month().year())
                                    .foregroundColor(Color("AppTextSecondary"))
                            } else {
                                Text(L10n.Profile.selectDate)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Profile.fieldBirthDate)
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                        if let date = selectedDate {
                            Text(date, format: .dateTime.day().month().year())
                                .foregroundColor(Color("AppTextPrimary"))
                        } else {
                            Text(L10n.Profile.notSpecified)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                }
            }

            if isEditing && showPicker {
                DatePicker(
                    L10n.Profile.datePickerTitle,
                    selection: dateBinding,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
        }
    }
}
