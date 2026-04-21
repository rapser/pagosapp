//
//  PaymentFilter.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import Foundation

enum PaymentFilterUI: String, CaseIterable, Identifiable {
    case currentMonth = "Próximos"
    case futureMonths = "Futuros"

    var id: String { self.rawValue }
}
