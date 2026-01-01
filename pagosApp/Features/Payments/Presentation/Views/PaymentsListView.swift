import SwiftUI

struct PaymentsListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: PaymentsListViewModel?
    @State private var showingAddPaymentSheet = false

    init() {
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
                    PaymentsListContentView(
                        viewModel: viewModel,
                        showingAddPaymentSheet: $showingAddPaymentSheet
                    )
                } else {
                    ProgressView("Cargando...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = dependencies.paymentDependencyContainer.makePaymentsListViewModel()

                // Only fetch on first load - subsequent updates come from SwiftData notifications
                Task {
                    await viewModel?.fetchPayments()
                }
            }
        }
    }
}
