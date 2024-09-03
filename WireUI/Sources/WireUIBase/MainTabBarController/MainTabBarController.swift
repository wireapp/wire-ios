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
        case contacts, conversations, folders, archive
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
        setupTabs()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupTabs() {
        viewControllers = Tab.allCases.map { _ in UINavigationController() }

        for tab in Tab.allCases {
            let tabBarItem: UITabBarItem
            switch tab {
            case .contacts:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.contacts.title", bundle: .module, comment: ""),
                    image: .init(resource: .TabBar.contactsOutline),
                    selectedImage: .init(resource: .TabBar.contactsFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.contacts.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.contacts.hint", bundle: .module, comment: "")

            case .conversations:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.conversations.title", bundle: .module, comment: ""),
                    image: .init(systemName: "text.bubble"),
                    selectedImage: .init(systemName: "text.bubble.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.conversations.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.conversations.hint", bundle: .module, comment: "")

            case .folders:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.folders.title", bundle: .module, comment: ""),
                    image: .init(resource: .TabBar.foldersOutline),
                    selectedImage: .init(resource: .TabBar.foldersFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.folders.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.folders.hint", bundle: .module, comment: "")

            case .archive:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.archived.title", bundle: .module, comment: ""),
                    image: .init(systemName: "archivebox"),
                    selectedImage: .init(systemName: "archivebox.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.archived.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.archived.hint", bundle: .module, comment: "")
            }
            viewControllers?[tab.rawValue].tabBarItem = tabBarItem
        }

        selectedIndex = Tab.conversations.rawValue
        // TODO: [WPB-6647] use `ColorTheme` instead of `SemanticColors`
        tabBar.backgroundColor = SemanticColors.View.backgroundDefault
        tabBar.unselectedItemTintColor = SemanticColors.Label.textTabBar
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
