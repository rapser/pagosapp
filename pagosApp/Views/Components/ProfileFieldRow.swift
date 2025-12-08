//
//  ProfileFieldRow.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct ProfileFieldRow: View {
    let icon: String
    let title: String
    let value: String
    let isOptional: Bool
    
    init(icon: String, title: String, value: String?, isOptional: Bool = true) {
        self.icon = icon
        self.title = title
        self.value = value ?? "No especificado"
        self.isOptional = isOptional
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
                Text(value)
                    .foregroundColor(textColor)
            }
        }
    }
    
    private var textColor: Color {
        if !isOptional || value != "No especificado" {
            return Color("AppTextPrimary")
        }
        return Color("AppTextSecondary")
    }
}
