import SwiftUI

struct PaymentDetailsSection: View {
    @Binding var name: String
    @Binding var category: PaymentCategory
    @Binding var dueDate: Date
    let showPaidToggle: Bool
    @Binding var isPaid: Bool

    init(
        name: Binding<String>,
        category: Binding<PaymentCategory>,
        dueDate: Binding<Date>,
        showPaidToggle: Bool = false,
        isPaid: Binding<Bool> = .constant(false)
    ) {
        self._name = name
        self._category = category
        self._dueDate = dueDate
        self.showPaidToggle = showPaidToggle
        self._isPaid = isPaid
    }

    var body: some View {
        Section(header: Text(L10n.Payments.Details.section)) {
            TextField(L10n.Payments.Details.namePlaceholder, text: $name)

            Picker(L10n.Payments.Details.category, selection: $category) {
                ForEach(PaymentCategory.allCases, id: \.self) { cat in
                    Text(L10n.Payments.categoryDisplayName(cat)).tag(cat)
                }
            }

            DatePicker(L10n.Payments.Details.dueDate, selection: $dueDate, displayedComponents: .date)

            if showPaidToggle {
                Toggle(isOn: $isPaid) {
                    Text(L10n.Payments.Details.paid)
                }
            }
        }
    }
}
