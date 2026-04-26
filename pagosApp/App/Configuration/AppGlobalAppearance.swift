//
//  AppGlobalAppearance.swift
//  pagosApp
//
//  Global UIKit appearance (navigation bar, tab bar, segmented control).
//  Must run on the main actor: `UIView` appearance APIs are main-actor-isolated
//  (stricter in recent SDKs). Call once from a SwiftUI view via `.onAppear`.
//

import SwiftUI
import UIKit

@MainActor
enum AppGlobalAppearance {
    private static var didApply = false

    /// Idempotent: safe to call from `onAppear` on the root `ContentView`.
    static func applyIfNeeded() {
        guard !didApply else { return }
        didApply = true
        applyNavigationBar()
        applyTabBar()
        applySegmentedControl()
    }

    private static func applyNavigationBar() {
        let primary = UIColor(named: "AppPrimary") ?? .systemBlue

        let appearance = UINavigationBarAppearance()
        // System-style bar: light (or dark) material, not a solid brand background.
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: primary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: primary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        let button = UIBarButtonItemAppearance()
        button.normal.titleTextAttributes = [.foregroundColor: primary]
        appearance.buttonAppearance = button
        appearance.doneButtonAppearance = button

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        // Back chevron, bar button symbols, and SF Symbol items use app primary.
        UINavigationBar.appearance().tintColor = primary
    }

    private static func applyTabBar() {
        UITabBar.appearance().backgroundColor = UIColor(named: "AppBackground")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AppTextSecondary")
        UITabBar.appearance().tintColor = UIColor(named: "AppPrimary")
    }

    private static func applySegmentedControl() {
        UISegmentedControl.appearance().backgroundColor = UIColor(named: "SegmentedBackground")
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            } else {
                return .white
            }
        }
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [
                .foregroundColor: UIColor { traitCollection in
                    if traitCollection.userInterfaceStyle == .dark {
                        return .white
                    } else {
                        return UIColor(named: "AppPrimary") ?? .systemBlue
                    }
                }
            ],
            for: .selected
        )
    }
}
