//
//  EditableTextFieldRow.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct EditableTextFieldRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 25)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .foregroundColor(Color("AppTextPrimary"))
        }
    }
}
