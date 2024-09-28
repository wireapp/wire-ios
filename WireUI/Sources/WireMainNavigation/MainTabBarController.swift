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

// TODO: rotating the call screen doesn't seem to work

/// A subclass of `UITabBarController` which configures its `viewControllers` property to match
/// ``MainTabBarControllerContent``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController<

    ConversationList: MainConversationListProtocol,
    Conversation: UIViewController,
    Archive: UIViewController,
    Connect: UIViewController,
    Settings: UIViewController

>: UITabBarController, MainTabBarControllerProtocol {

    public typealias Content = MainTabBarControllerContent

    // MARK: - Public Properties

    public weak var conversationList: ConversationList? {
        didSet {
            conversationListNavigationController?.viewControllers = [conversationList].compactMap { $0 }
            conversationListNavigationController?.view.layoutIfNeeded()
        }
    }

    public var archive: Archive? {
        didSet {
            archiveNavigationController?.viewControllers = [archive].compactMap { $0 }
            archiveNavigationController?.view.layoutIfNeeded()
        }
    }

    public var settings: Settings? {
        didSet {
            settingsNavigationController?.viewControllers = [settings].compactMap { $0 }
            settingsNavigationController?.view.layoutIfNeeded()
        }
    }

    public var selectedContent: MainTabBarControllerContent {
        get { .init(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Private Properties

    private weak var conversationListNavigationController: UINavigationController?
    private weak var archiveNavigationController: UINavigationController?
    private weak var settingsNavigationController: UINavigationController?

    // MARK: - Life Cycle

    public required init() {
        super.init(nibName: nil, bundle: nil)
        setupTabs()
        setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupTabs() {
        let conversationListNavigationController = UINavigationController()
        self.conversationListNavigationController = conversationListNavigationController

        let archiveNavigationController = UINavigationController()
        self.archiveNavigationController = archiveNavigationController

        let settingsNavigationController = UINavigationController()
        self.settingsNavigationController = settingsNavigationController

        viewControllers = [
            conversationListNavigationController,
            archiveNavigationController,
            settingsNavigationController
        ]

        for content in Content.allCases {
            switch content {
            case .conversations:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.conversations.title", bundle: .module),
                    image: .init(systemName: "text.bubble"),
                    selectedImage: .init(systemName: "text.bubble.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.conversations.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.conversations.hint", bundle: .module)
                conversationListNavigationController.tabBarItem = tabBarItem

            case .archive:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.archived.title", bundle: .module),
                    image: .init(systemName: "archivebox"),
                    selectedImage: .init(systemName: "archivebox.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.archived.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.archived.hint", bundle: .module)
                archiveNavigationController.tabBarItem = tabBarItem

            case .settings:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.settings.title", bundle: .module),
                    image: .init(systemName: "gearshape"),
                    selectedImage: .init(systemName: "gearshape.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarSettingsButton"
                // TODO: [WPB-9727] missing string localization
                tabBarItem.accessibilityLabel = String(localized: "tabBar.settings.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.settings.hint", bundle: .module)
                settingsNavigationController.tabBarItem = tabBarItem
            }
        }
        selectedContent = .conversations
    }

    private func setupAppearance() {
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = .systemGray
        tabBarItemAppearance.normal.titleTextAttributes[.foregroundColor] = UIColor.systemGray

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance

        tabBar.standardAppearance = tabBarAppearance
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 18.0, *) {
            traitOverrides.horizontalSizeClass = .compact
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarControllerPreview()
}
