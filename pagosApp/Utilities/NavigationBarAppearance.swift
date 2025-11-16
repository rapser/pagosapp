//
//  NavigationBarAppearance.swift
//  pagosApp
//
//  Configuración de apariencia del Navigation Bar con colores pagosApp
//

import SwiftUI
import UIKit

// MARK: - UIColor Extensions para pagosApp

extension UIColor {
    static let pagosAppBluePrimary = UIColor(hex: "#002B75")      // Azul oscuro corporativo
    static let pagosAppBlueSecondary = UIColor(hex: "#003DA5")    // Azul medio
    static let pagosAppYellowPrimary = UIColor(hex: "#FFD100")

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Navigation Bar Style

extension View {
    /// Aplica el estilo pagosApp al Navigation Bar
    func pagosAppNavigationBarStyle() -> some View {
        self.onAppear {
            configureNavigationBarAppearance()
        }
    }
}

private func configureNavigationBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()

    // Fondo azul pagosApp
    appearance.backgroundColor = UIColor.pagosAppBluePrimary

    // Título en blanco
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor.white,
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]

    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor.white,
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]

    // Botones y elementos en blanco
    let buttonAppearance = UIBarButtonItemAppearance()
    buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.buttonAppearance = buttonAppearance
    appearance.backButtonAppearance = buttonAppearance
    appearance.doneButtonAppearance = buttonAppearance

    // Color del tint (íconos, botones)
    UINavigationBar.appearance().tintColor = .white

    // Aplicar a todos los estados
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    if #available(iOS 15.0, *) {
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
}
