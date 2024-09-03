//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI
import WireDesign

/// A subclass of `UITabBarController` which preconfigures its `viewControllers` property to match
/// ``MainTabBarController.Tab``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController: UITabBarController {

    public enum Tab: Int, CaseIterable {
        case conversations, archive, settings
    }

    // MARK: - Tab Subscript and Index

    public subscript(tab tab: Tab) -> UINavigationController {
        viewControllers![tab.rawValue] as! UINavigationController
    }

    public var selectedTab: Tab {
        get { Tab(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Life Cycle

    public required init() {
        super.init(nibName: nil, bundle: nil)
        setupAppearance()
        setupTabs()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupAppearance() {

        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = ColorTheme.Base.secondaryText
        tabBarItemAppearance.normal.titleTextAttributes[.foregroundColor] = ColorTheme.Base.secondaryText

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = ColorTheme.Backgrounds.background
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
    }

    private func setupTabs() {
        viewControllers = Tab.allCases.map { _ in UINavigationController() }

        for tab in Tab.allCases {
            let tabBarItem: UITabBarItem
            switch tab {

            case .conversations:
                tabBarItem = .init(
                    title: String(localized: "tabBar.conversations.title", bundle: .module),
                    image: .init(systemName: "text.bubble"),
                    selectedImage: .init(systemName: "text.bubble.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.conversations.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.conversations.hint", bundle: .module)

            case .archive:
                tabBarItem = .init(
                    title: String(localized: "tabBar.archived.title", bundle: .module),
                    image: .init(systemName: "archivebox"),
                    selectedImage: .init(systemName: "archivebox.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.archived.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.archived.hint", bundle: .module)

            case .settings:
                tabBarItem = .init(
                    title: String(localized: "tabBar.settings.title", bundle: .module),
                    image: .init(systemName: "gearshape"),
                    selectedImage: .init(systemName: "gearshape.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarSettingsButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.settings.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.settings.hint", bundle: .module)

            }
            viewControllers?[tab.rawValue].tabBarItem = tabBarItem
        }

        selectedIndex = Tab.conversations.rawValue
        tabBar.backgroundColor = ColorTheme.Backgrounds.background
        tabBar.unselectedItemTintColor = ColorTheme.Base.secondaryText
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarController_Preview()
}

@MainActor
func MainTabBarController_Preview() -> MainTabBarController {
    let tabBarController = MainTabBarController()
    for tab in MainTabBarController.Tab.allCases {
        tabBarController[tab: tab].viewControllers = [PlaceholderViewController()]
    }
    tabBarController.selectedTab = .conversations
    return tabBarController
}

private final class PlaceholderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.Backgrounds.surfaceVariant
        navigationItem.title = navigationController!.tabBarItem.title
        let imageView = UIImageView(image: navigationController!.tabBarItem.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        imageView.transform = .init(scaleX: 3, y: 3)
    }
}
