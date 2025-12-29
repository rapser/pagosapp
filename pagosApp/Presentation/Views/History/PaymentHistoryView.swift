import SwiftUI

struct PaymentHistoryView: View {
    @Environment(ErrorHandler.self) private var errorHandler
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: PaymentHistoryViewModel?

    init() {

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
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel
                    
                    VStack(spacing: 0) {
                        Picker("Filtrar", selection: $vm.selectedFilter) {
                            ForEach(PaymentHistoryFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if vm.isLoading {
                            Spacer()
                            ProgressView("Cargando historial...")
                            Spacer()
                        } else if vm.filteredPayments.isEmpty {
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
                                ForEach(vm.filteredPayments.map { PaymentMapper.toModel(from: $0) }) { payment in
                                    PaymentRowView(payment: payment, onToggleStatus: {})
                                        .opacity(payment.isPaid ? 1.0 : 0.7)
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                await vm.refresh()
                            }
                        }
                    }
                    .navigationTitle("Historial de Pagos")
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.paymentDependencyContainer.makePaymentHistoryViewModel(errorHandler: errorHandler)
            }
        }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}