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

// TODO: rotating the call screen doesn't seem to work <-

/// A subclass of `UITabBarController` which configures its `viewControllers` property to match
/// ``MainTabBarControllerContent``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController<

    ConversationList: MainConversationListProtocol,
    Conversation: MainConversationProtocol

>: UITabBarController, MainTabBarControllerProtocol {

    public typealias Archive = UIViewController
    public typealias Settings = UIViewController
    public typealias SettingsContent = UIViewController

    // MARK: - Public Properties

    public var conversationList: ConversationList? {
        get { _conversationList }
        set { setConversationList(newValue, animated: false) }
    }

    public var archive: Archive? {
        get { _archive }
        set { setArchive(newValue, animated: false) }
    }

    public var settings: Settings? {
        get { _settings }
        set { setSettings(newValue, animated: false) }
    }

    public var conversation: Conversation? {
        get { _conversation }
        set { setConversation(newValue, animated: false) }
    }

    public var settingsContent: SettingsContent? {
        get { _settingsContent }
        set { setSettingsContent(newValue, animated: false) }
    }

    public var selectedContent: MainTabBarControllerContent {
        get { .init(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Private Properties

    private weak var conversationListNavigationController: UINavigationController!
    private weak var archiveNavigationController: UINavigationController!
    private weak var settingsNavigationController: UINavigationController!

    private weak var _conversationList: ConversationList?
    private weak var _archive: Archive?
    private weak var _settings: Settings?
    private weak var _conversation: Conversation?
    private weak var _settingsContent: SettingsContent?

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

        for content in MainTabBarControllerContent.allCases {
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

    // MARK: - Accessors

    private func setConversationList(_ conversationList: ConversationList?, animated: Bool) {
        _conversationList = conversationList

        let viewControllers = [conversationList, conversation].compactMap { $0 }
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    private func setArchive(_ archive: Archive?, animated: Bool) {
        _archive = archive

        let viewControllers = [archive].compactMap { $0 }
        archiveNavigationController.setViewControllers(viewControllers, animated: animated)
        archiveNavigationController.view.layoutIfNeeded()
    }

    private func setSettings(_ settings: Settings?, animated: Bool) {
        _settings = settings

        let viewControllers = [settings].compactMap { $0 }
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }

    public func setConversation(_ conversation: Conversation?, animated: Bool) {
        _conversation = conversation

        if conversationList == nil, conversation != nil {
            return assertionFailure("conversationList == nil, conversation != nil")
        }

        let viewControllers = [conversationList, conversation].compactMap { $0 }
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    public func setSettingsContent(_ settingsContent: SettingsContent?, animated: Bool) {
        _settingsContent = settingsContent

        if settings == nil, settingsContent != nil {
            return assertionFailure("settings == nil, settingsContent != nil")
        }

        let viewControllers = [settings, settingsContent].compactMap { $0 }
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarControllerPreview()
}
