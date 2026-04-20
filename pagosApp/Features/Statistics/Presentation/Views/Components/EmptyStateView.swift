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
        let currencyName = currency == .pen ? L10n.Statistics.currencySoles : L10n.Statistics.currencyDollars
        return L10n.Statistics.emptyNoPayments(currencyName)
    }

    private var description: String {
        L10n.Statistics.emptyForFilter(L10n.Statistics.periodDisplayName(filter))
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
