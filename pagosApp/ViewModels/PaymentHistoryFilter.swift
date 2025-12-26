//
//  PaymentHistoryFilter.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

enum PaymentHistoryFilter: String, CaseIterable, Identifiable {
    case completed = "Completados"
    case overdue = "Vencidos"
    case all = "Todos"

    var id: String { self.rawValue }
}
