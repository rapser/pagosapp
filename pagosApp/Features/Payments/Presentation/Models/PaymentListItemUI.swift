//
//  PaymentListItem.swift
//  pagosApp
//
//  Enum to represent either a payment group or individual payment in the list
//  Clean Architecture: Presentation layer
//

import Foundation

/// Represents an item in the payments list - either a group or individual payment
enum PaymentListItemUI: Identifiable {
    case group(PaymentGroupUI)
    case individual(PaymentUI)

    var id: UUID {
        switch self {
        case .group(let group):
            return group.id
        case .individual(let payment):
            return payment.id
        }
    }

    var dueDate: Date {
        switch self {
        case .group(let group):
            return group.dueDate
        case .individual(let payment):
            return payment.dueDate
        }
    }
}
