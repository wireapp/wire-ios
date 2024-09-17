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

/// A subclass of `UITabBarController` which preconfigures its `viewControllers` property to match
/// ``MainTabBarController.Tab``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController: UITabBarController, MainTabBarControllerProtocol {

    public typealias ConversationList = UIViewController
    public typealias Conversation = UIViewController
    public typealias Archive = UIViewController
    public typealias Settings = UIViewController

    // MARK: - Public Properties

    public var conversations: (conversationList: ConversationList, conversation: Conversation?)? {
        get {
            let navigationController = viewControllers![MainTabBarControllerContent.conversations.rawValue] as! UINavigationController
            guard !navigationController.viewControllers.isEmpty else { return nil }

            var viewControllers = navigationController.viewControllers
            let conversationList = viewControllers.removeFirst() as! ConversationList
            let conversation = viewControllers.first.map { $0 as! Conversation }
            return (conversationList, conversation)
        }
        set {
            let navigationController = viewControllers![MainTabBarControllerContent.conversations.rawValue] as! UINavigationController
            if let newValue {
                navigationController.viewControllers = [newValue.conversationList, newValue.conversation].compactMap { $0 }
            } else {
                navigationController.viewControllers.removeAll()
            }
        }
    }

    public var archive: Archive? {
        get {
            let navigationController = viewControllers![MainTabBarControllerContent.archive.rawValue] as! UINavigationController
            return navigationController.viewControllers.first.map { $0 as! Archive }
        }
        set {
            let navigationController = viewControllers![MainTabBarControllerContent.archive.rawValue] as! UINavigationController
            navigationController.viewControllers = [newValue].compactMap { $0 }
        }
    }

    public var settings: Settings? {
        get {
            let navigationController = viewControllers![MainTabBarControllerContent.settings.rawValue] as! UINavigationController
            return navigationController.viewControllers.first.map { $0 as! Settings }
        }
        set {
            let navigationController = viewControllers![MainTabBarControllerContent.settings.rawValue] as! UINavigationController
            navigationController.viewControllers = [newValue].compactMap { $0 }
        }
    }

    public var selectedContent: MainTabBarControllerContent {
        get { .init(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Tab Subscript and Index

    // TODO: remove
    @available(*, deprecated, message: "Use properties")
    public subscript(tab tab: MainTabBarControllerContent) -> UINavigationController {
        viewControllers![tab.rawValue] as! UINavigationController
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
        viewControllers = MainTabBarControllerContent.allCases.map { _ in UINavigationController() }

        for tab in MainTabBarControllerContent.allCases {
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
                // TODO: [WPB-9727] missing string localization
                tabBarItem.accessibilityLabel = String(localized: "tabBar.settings.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.settings.hint", bundle: .module)
            }
            viewControllers?[tab.rawValue].tabBarItem = tabBarItem
        }

        selectedIndex = MainTabBarControllerContent.conversations.rawValue
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarController_Preview()
}

@MainActor
func MainTabBarController_Preview() -> some MainTabBarControllerProtocol {
    let tabBarController = MainTabBarController()
    for tab in MainTabBarControllerContent.allCases {
        tabBarController[tab: tab].viewControllers = [PlaceholderViewController()]
    }
    tabBarController.selectedContent = .conversations
    return tabBarController
}

private final class PlaceholderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .yellow // ColorTheme.Backgrounds.surfaceVariant
        navigationItem.title = navigationController!.tabBarItem.title
        let imageView = UIImageView(image: navigationController!.tabBarItem.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        imageView.transform = .init(scaleX: 3, y: 3)
    }
}
