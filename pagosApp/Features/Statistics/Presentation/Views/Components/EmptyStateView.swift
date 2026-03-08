//
//  EmptyStateView.swift
//  pagosApp
//
//  Statistics empty state: uses GenericEmptyStateView with currency/filter-specific copy
//

import SwiftUI
import Charts

struct EmptyStateView: View {
    let currency: Currency
    let filter: StatsFilter

    private var title: String {
        "No hay pagos en \(currency == .pen ? "Soles" : "Dólares")"
    }

    private var description: String {
        "para \"\(filter.rawValue)\""
    }

    var body: some View {
        GenericEmptyStateView(
            icon: "chart.pie",
            title: title,
            description: description
        )
        .padding(.vertical, 60)
    }
}
