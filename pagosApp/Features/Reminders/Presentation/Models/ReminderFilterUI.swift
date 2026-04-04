//
//  ReminderFilterUI.swift
//  pagosApp
//
//  Filter enum for the reminders list segmented control.
//  Clean Architecture - Presentation Layer
//

import Foundation

enum ReminderFilterUI: String, CaseIterable, Identifiable {
    case currentMonth = "Próximos"
    case futureMonths = "Futuros"

    var id: String { self.rawValue }
}
