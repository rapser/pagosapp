import SwiftUI

struct MonthYearHeaderView: View {
    let monthYearString: String
    let isExpanded: Bool
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToggleExpand: () -> Void

    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color("AppPrimary"))
            }

            Spacer()

            Button(action: { withAnimation(.spring(response: 0.3)) { onToggleExpand() } }) {
                HStack(spacing: 6) {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AppTextPrimary"))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color("AppPrimary"))
                }
            }

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("AppPrimary"))
            }
        }
        .padding(.horizontal)
    }
}
