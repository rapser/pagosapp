//
//  UserProfileMock.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import Foundation

#if DEBUG
extension UserProfile {
    static var mock: UserProfile {
        UserProfile(
            userId: UUID(),
            fullName: "Juan Pérez",
            email: "juan.perez@ejemplo.com",
            phone: "+51 987654321",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15)),
            gender: .masculino,
            country: "Perú",
            city: "Lima",
            preferredCurrency: .pen
        )
    }

    static var mockMinimal: UserProfile {
        UserProfile(
            userId: UUID(),
            fullName: "María García",
            email: "maria.garcia@ejemplo.com",
            preferredCurrency: .usd
        )
    }
}
#endif
