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

// TODO: [WPB-11448] Bug: The call screen doesn't rotate to landscape

/// A subclass of `UITabBarController` which configures its `viewControllers` property to match
/// ``MainTabBarControllerContent``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController<

    ConversationListUI: MainConversationListUIProtocol,
    ConversationUI: MainConversationUIProtocol

>: UITabBarController, MainTabBarControllerProtocol {

    public typealias ArchiveUI = UIViewController
    public typealias SettingsUI = UIViewController

    // MARK: - Public Properties

    public var conversationListUI: ConversationListUI? {
        get { _conversationListUI }
        set { setConversationListUI(newValue, animated: false) }
    }

    public var foldersUI: UIViewController? {
        get { _foldersUI }
        set { setFoldersUI(newValue, animated: false) }
    }

    public var archiveUI: ArchiveUI? {
        get { _archiveUI }
        set { setArchiveUI(newValue, animated: false) }
    }

    public var settingsUI: SettingsUI? {
        get { _settingsUI }
        set { setSettingsUI(newValue, animated: false) }
    }

    public var conversationUI: ConversationUI? {
        get { _conversationUI }
        set { setConversationUI(newValue, animated: false) }
    }

    public var settingsContentUI: UIViewController? {
        get { _settingsContentUI }
        set { setSettingsContentUI(newValue, animated: false) }
    }

    public var selectedContent: MainTabBarControllerContent {
        get { .init(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Private Properties

    private weak var contactsNavigationController: UINavigationController!
    private weak var conversationListNavigationController: UINavigationController!
    private weak var foldersNavigationController: UINavigationController!
    private weak var archiveNavigationController: UINavigationController!
    private /* weak */ var settingsNavigationController: UINavigationController! // TODO: [WPB-6647] make this property weak as well

    private weak var _conversationListUI: ConversationListUI?
    private weak var _foldersUI: UIViewController?
    private weak var _archiveUI: ArchiveUI?
    private weak var _settingsUI: SettingsUI?
    private weak var _conversationUI: ConversationUI?
    private weak var _settingsContentUI: UIViewController?

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
        let contactsNavigationController = UINavigationController()
        self.contactsNavigationController = contactsNavigationController

        let conversationListNavigationController = UINavigationController()
        self.conversationListNavigationController = conversationListNavigationController

        let foldersNavigationController = UINavigationController()
        self.foldersNavigationController = foldersNavigationController

        let archiveNavigationController = UINavigationController()
        self.archiveNavigationController = archiveNavigationController

        let settingsNavigationController = UINavigationController()
        self.settingsNavigationController = settingsNavigationController

        viewControllers = [
            contactsNavigationController,
            conversationListNavigationController,
            foldersNavigationController,
            archiveNavigationController,
            settingsNavigationController
        ]

        for content in MainTabBarControllerContent.allCases {
            switch content {
            case .contacts:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.contacts.title", bundle: .module),
                    image: .init(systemName: "person"),
                    selectedImage: .init(systemName: "person.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.contacts.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.contacts.hint", bundle: .module)
                contactsNavigationController.tabBarItem = tabBarItem

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

            case .folders:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.folders.title", bundle: .module),
                    image: .init(systemName: "folder"),
                    selectedImage: .init(systemName: "folder.fill")
                tabBarItem.accessibilityLabel = String(
                    localized: "tabBar.conversations.description",
                    table: "Accessibility",
                    bundle: .module
                )
                tabBarItem.accessibilityHint = String(
                    localized: "tabBar.conversations.hint",
                    table: "Accessibility",
                    bundle: .module
                )
                tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
                tabBarItem.accessibilityLabel = String(localized: "tabBar.folders.description", bundle: .module)
                tabBarItem.accessibilityHint = String(localized: "tabBar.folders.hint", bundle: .module)
                foldersNavigationController.tabBarItem = tabBarItem

            case .archive:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.archived.title", bundle: .module),
                    image: .init(systemName: "archivebox"),
                    selectedImage: .init(systemName: "archivebox.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = String(
                    localized: "tabBar.archived.description",
                    table: "Accessibility",
                    bundle: .module
                )
                tabBarItem.accessibilityHint = String(
                    localized: "tabBar.archived.hint",
                    table: "Accessibility",
                    bundle: .module
                )
                archiveNavigationController.tabBarItem = tabBarItem

            case .settings:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.settings.title", bundle: .module),
                    image: .init(systemName: "gearshape"),
                    selectedImage: .init(systemName: "gearshape.fill")
                )
                tabBarItem.accessibilityIdentifier = "bottomBarSettingsButton"
                tabBarItem.accessibilityLabel = String(
                    localized: "tabBar.settings.description",
                    table: "Accessibility",
                    bundle: .module
                )
                tabBarItem.accessibilityHint = String(
                    localized: "tabBar.settings.hint",
                    table: "Accessibility",
                    bundle: .module
                )
                settingsNavigationController.tabBarItem = tabBarItem
            }
        }
        viewControllers?.removeLast() // this line will be removed with navigation overhaul
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

    private func setConversationListUI(_ conversationListUI: ConversationListUI?, animated: Bool) {
        _conversationListUI = conversationListUI

        let viewControllers = [conversationListUI, conversationUI].compactMap { $0 }
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    private func setFoldersUI(_ foldersUI: UIViewController?, animated: Bool) {
        _foldersUI = foldersUI

        let viewControllers = [foldersUI].compactMap { $0 }
        foldersNavigationController.setViewControllers(viewControllers, animated: animated)
        foldersNavigationController.view.layoutIfNeeded()
    }

    private func setArchiveUI(_ archiveUI: ArchiveUI?, animated: Bool) {
        _archiveUI = archiveUI

        let viewControllers = [archiveUI].compactMap { $0 }
        archiveNavigationController.setViewControllers(viewControllers, animated: animated)
        archiveNavigationController.view.layoutIfNeeded()
    }

    private func setSettingsUI(_ settingsUI: SettingsUI?, animated: Bool) {
        _settingsUI = settingsUI

        let viewControllers = [settingsUI].compactMap { $0 }
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }

    public func setConversationUI(_ conversationUI: ConversationUI?, animated: Bool) {
        _conversationUI = conversationUI

        if conversationListUI == nil, conversationUI != nil {
            return assertionFailure("conversationListUI == nil, conversationUI != nil")
        }

        let viewControllers = [conversationListUI, conversationUI].compactMap { $0 }
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    public func setSettingsContentUI(_ settingsContentUI: UIViewController?, animated: Bool) {
        _settingsContentUI = settingsContentUI

        if settingsUI == nil, settingsContentUI != nil {
            return assertionFailure("settingsUI == nil, settingsContentUI != nil")
        }

        let viewControllers = [settingsUI, settingsContentUI].compactMap { $0 }
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarControllerPreview()
}
