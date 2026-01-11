import SwiftUI

struct PaymentHistoryView: View {
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
                    HistoryContentView(viewModel: viewModel)
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.historyDependencyContainer.makePaymentHistoryViewModel()
            }
        }
        .onChange(of: viewModel?.selectedFilter) { oldValue, newValue in
            if let newValue = newValue, let vm = viewModel {
                Task {
                    await vm.updateFilter(newValue)
                }
            }
        }
    }
}


struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}