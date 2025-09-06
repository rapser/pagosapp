import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color("AppTextPrimary").opacity(0.4).edgesIgnoringSafeArea(.all) // Themed color
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AppTextPrimary"))) // Themed color
                .scaleEffect(2.0, anchor: .center)
                .padding()
                .background(Color("AppBackground").opacity(0.7)) // Themed color
                .cornerRadius(10)
        }
    }
}

#Preview {
    LoadingView()
}