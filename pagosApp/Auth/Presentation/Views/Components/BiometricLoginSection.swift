import SwiftUI

struct BiometricLoginSection: View {
    let biometricIcon: String
    let biometricName: String
    let isLoading: Bool
    let onBiometricLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: biometricIcon)
                .font(.system(size: 80))
                .foregroundColor(Color("AppPrimary"))

            Text("Usa \(biometricName) para acceder")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.top, 8)

            Button(action: onBiometricLogin) {
                HStack {
                    Image(systemName: biometricIcon)
                    Text("Ingresar con \(biometricName)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AppPrimary"))
                .cornerRadius(10)
            }
            .padding(.top, 20)
            .disabled(isLoading)
        }
    }
}
