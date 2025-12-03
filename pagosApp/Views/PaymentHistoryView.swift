//
//  PaymentHistoryView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import SwiftUI
import SwiftData

struct PaymentHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PaymentHistoryViewModel

    init() {
        // Create a temporary placeholder - will be replaced with actual context in body
        let container = try! ModelContainer(for: Payment.self)
        let context = ModelContext(container)
        _viewModel = StateObject(wrappedValue: PaymentHistoryViewModel(modelContext: context))

        // Configurar segmented control con soporte para modo oscuro
        UISegmentedControl.appearance().backgroundColor = UIColor(named: "SegmentedBackground")

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            } else {
                return .white
            }
        }

        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .white
                } else {
                    return UIColor(named: "AppPrimary") ?? .systemBlue
                }
            }
        ], for: .selected)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Filtrar", selection: $viewModel.selectedFilter) {
                    ForEach(PaymentHistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Cargando historial...")
                    Spacer()
                } else if viewModel.filteredPayments.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(Color("AppTextSecondary"))

                        Text("No hay pagos en el historial")
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))

                        Text("Los pagos completados y vencidos aparecerán aquí")
                            .font(.subheadline)
                            .foregroundColor(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredPayments) { payment in
                            PaymentRowView(payment: payment, onToggleStatus: {}) // Empty closure for history
                                .opacity(payment.isPaid ? 1.0 : 0.7) // Dim overdue payments
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Historial de Pagos")
        }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}