import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2.0, anchor: .center)
                .padding()
                .background(Color.gray.opacity(0.7))
                .cornerRadius(10)
        }
    }
}

#Preview {
    LoadingView()
}
