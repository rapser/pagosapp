import SwiftUI
import SwiftData

struct PaymentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PaymentsListViewModel?
    @State private var showingAddPaymentSheet = false

    init() {
        // ViewModel will be created in onAppear with real modelContext

        // Configurar segmented control con soporte para modo oscuro
        // Fondo: azul en light mode, gris oscuro en dark mode
        UISegmentedControl.appearance().backgroundColor = UIColor(named: "SegmentedBackground")

        // Segmento seleccionado: blanco en light mode, azul primario en dark mode
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            } else {
                return .white
            }
        }

        // Texto no seleccionado: blanco siempre
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        // Texto seleccionado: azul en light mode, blanco en dark mode
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
            Group {
                if let viewModel = viewModel {
                    @Bindable var vm = viewModel
                    
                    VStack {
                        Picker("Filtrar", selection: $vm.selectedFilter) {
                            ForEach(PaymentFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if vm.isLoading {
                            ProgressView("Sincronizando...")
                        } else {
                            List {
                                ForEach(vm.filteredPayments) { payment in
                                    NavigationLink(destination: EditPaymentView(payment: payment)) {
                                        PaymentRowView(payment: payment, onToggleStatus: {
                                            vm.togglePaymentStatus(payment)
                                        })
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            vm.deletePayment(payment)
                                        } label: {
                                            Label("Borrar", systemImage: "trash.fill")
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                vm.refresh()
                            }
                        }
                    }
                    .navigationTitle("Mis Pagos")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingAddPaymentSheet = true }) {
                                Image(systemName: "plus")
                                    .foregroundColor(Color(uiColor: UIColor { traitCollection in
                                        if traitCollection.userInterfaceStyle == .dark {
                                            return .white
                                        } else {
                                            return UIColor(named: "AppPrimary") ?? .systemBlue
                                        }
                                    }))
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddPaymentSheet) {
                        AddPaymentView()
                            .onDisappear {
                                viewModel.refresh()
                            }
                    }
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PaymentsListViewModel(modelContext: modelContext)
            }
        }
    }
}
