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
        Section(header: Text("Detalles del Pago")) {
            TextField("Nombre del pago", text: $name)

            Picker("Categoría", selection: $category) {
                ForEach(PaymentCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }

            DatePicker("Fecha de Vencimiento", selection: $dueDate, displayedComponents: .date)

            if showPaidToggle {
                Toggle(isOn: $isPaid) {
                    Text("Pagado")
                }
            }
        }
    }
}
