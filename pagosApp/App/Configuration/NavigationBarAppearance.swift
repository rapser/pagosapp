import UIKit

struct NavigationBarAppearance {
    static func configure() {
        // Configuración para modo claro
        let lightAppearance = UINavigationBarAppearance()
        lightAppearance.configureWithOpaqueBackground()
        lightAppearance.backgroundColor = UIColor(named: "AppPrimary")

        lightAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        lightAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        let lightButtonAppearance = UIBarButtonItemAppearance()
        lightButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        lightAppearance.buttonAppearance = lightButtonAppearance
        lightAppearance.doneButtonAppearance = lightButtonAppearance

        // Configuración para modo oscuro
        let darkAppearance = UINavigationBarAppearance()
        darkAppearance.configureWithOpaqueBackground()
        darkAppearance.backgroundColor = UIColor(named: "AppPrimary")

        darkAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        darkAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        let darkButtonAppearance = UIBarButtonItemAppearance()
        darkButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        darkAppearance.buttonAppearance = darkButtonAppearance
        darkAppearance.doneButtonAppearance = darkButtonAppearance

        // Asignar la apariencia a la barra de navegación
        UINavigationBar.appearance().standardAppearance = lightAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = lightAppearance
        UINavigationBar.appearance().compactAppearance = lightAppearance

        // Tint color para los íconos de los botones (se adaptará automáticamente)
        UINavigationBar.appearance().tintColor = .white
    }
}
