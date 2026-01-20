//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLocators

// TODO: [WPB-11448] Bug: The call screen doesn't rotate to landscape

/// A subclass of `UITabBarController` which configures its `viewControllers` property to match
/// ``MainTabBarControllerContent``'s cases. After initialization each tab contains an empty navigation controller.
public final class MainTabBarController<

    ConversationListUI: MainConversationListUIProtocol,
    ConversationUI: MainConversationUIProtocol

>: UITabBarController, MainTabBarControllerProtocol {

    public typealias ArchiveUI = UIViewController
    public typealias SettingsUI = UIViewController
    public typealias MeetingsUI = UIViewController
    public typealias FilesUI = UIViewController

    // MARK: - Public Properties

    public var conversationListUI: ConversationListUI? {
        get { _conversationListUI }
        set { setConversationListUI(newValue, animated: false) }
    }

    public var archiveUI: ArchiveUI? {
        get { _archiveUI }
        set { setArchiveUI(newValue, animated: false) }
    }

    public var meetingsUI: MeetingsUI? {
        get { _meetingsUI }
        set { setMeetingsUI(newValue, animated: false) }
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

    public var filesUI: UIViewController? {
        get { _filesUI }
        set { setFilesUI(newValue, animated: false) }
    }

    public var selectedContent: MainTabBarControllerContent {
        get { .init(rawValue: selectedIndex) ?? .conversations }
        set { selectedIndex = newValue.rawValue }
    }

    // MARK: - Private Properties

    private weak var conversationListNavigationController: UINavigationController!
    private weak var archiveNavigationController: UINavigationController!
    private weak var meetingsNavigationController: UINavigationController?
    private weak var settingsNavigationController: UINavigationController!
    private weak var filesNavigationController: UINavigationController? // shown conditionally - when wire cells is
    // enabled.

    private weak var _conversationListUI: ConversationListUI?
    private weak var _filesUI: FilesUI?
    private weak var _archiveUI: ArchiveUI?
    private weak var _meetingsUI: MeetingsUI?
    private weak var _settingsUI: SettingsUI?
    private weak var _conversationUI: ConversationUI?
    private weak var _settingsContentUI: UIViewController?
    /// We should use DeveloperFlag 'wireMeetings' after moving it to WireFoundation:
    /// https://wearezeta.atlassian.net/browse/WPB-19065
    private var showMeetings: Bool
    private var showFiles: Bool

    // MARK: - Life Cycle

    public init(showMeetings: Bool, showFiles: Bool) {
        self.showMeetings = showMeetings
        self.showFiles = showFiles
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
        conversationListNavigationController.navigationBar.isTranslucent = false
        self.conversationListNavigationController = conversationListNavigationController

        if showFiles {
            let filesNavigationController = UINavigationController()
            filesNavigationController.navigationBar.isTranslucent = false
            self.filesNavigationController = filesNavigationController
        }

        let archiveNavigationController = UINavigationController()
        archiveNavigationController.navigationBar.isTranslucent = false
        self.archiveNavigationController = archiveNavigationController

        let settingsNavigationController = UINavigationController()
        settingsNavigationController.navigationBar.isTranslucent = false
        self.settingsNavigationController = settingsNavigationController

        var tabs: [UIViewController] = [
            conversationListNavigationController,
            archiveNavigationController,
            settingsNavigationController
        ]

        if showFiles, let filesNavigationController {
            tabs.insert(filesNavigationController, at: 1)
        }

        if showMeetings {
            let meetingsNavigationController = UINavigationController()
            meetingsNavigationController.navigationBar.isTranslucent = false
            self.meetingsNavigationController = meetingsNavigationController

            tabs.insert(meetingsNavigationController, at: 2)
        } else {
            meetingsNavigationController = nil
        }
        setViewControllers(tabs, animated: false)

        for content in MainTabBarControllerContent.allCases {
            switch content {
            case .conversations:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.conversations.title", bundle: .module),
                    image: .init(systemName: "text.bubble"),
                    selectedImage: .init(systemName: "text.bubble.fill")
                )
                tabBarItem
                    .accessibilityIdentifier = Locators.ConversationsPage.bottomBarRecentListButton.rawValue
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
                conversationListNavigationController.tabBarItem = tabBarItem

            case .archive:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.archived.title", bundle: .module),
                    image: .init(systemName: "archivebox"),
                    selectedImage: .init(systemName: "archivebox.fill")
                )
                tabBarItem.accessibilityIdentifier = Locators.ConversationsPage.bottomBarArchivedButton.rawValue
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

            case .meetings:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.meetings.title", bundle: .module),
                    image: .init(resource: .videoCall),
                    selectedImage: .init(resource: .videoCallFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarMeetingsButton"
                tabBarItem.accessibilityLabel = String(
                    localized: "tabBar.meetings.description",
                    table: "Accessibility",
                    bundle: .module
                )
                tabBarItem.accessibilityHint = String(
                    localized: "tabBar.meetings.hint",
                    table: "Accessibility",
                    bundle: .module
                )
                meetingsNavigationController?.tabBarItem = tabBarItem

            case .settings:
                let tabBarItem = UITabBarItem(
                    title: String(localized: "tabBar.settings.title", bundle: .module),
                    image: .init(systemName: "gearshape"),
                    selectedImage: .init(systemName: "gearshape.fill")
                )
                tabBarItem
                    .accessibilityIdentifier = Locators.ConversationsPage.bottomBarSettingsButton.rawValue
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

            case .files:
                setupFilesTabBarItem()
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

    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 18.0, *) {
            traitOverrides.horizontalSizeClass = .compact
        }
    }

    // MARK: - Accessors

    private func setConversationListUI(_ conversationListUI: ConversationListUI?, animated: Bool) {
        _conversationListUI = conversationListUI

        let viewControllers = [conversationListUI, conversationUI].compactMap(\.self)
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    private func setArchiveUI(_ archiveUI: ArchiveUI?, animated: Bool) {
        _archiveUI = archiveUI

        let viewControllers = [archiveUI].compactMap(\.self)
        archiveNavigationController.setViewControllers(viewControllers, animated: animated)
        archiveNavigationController.view.layoutIfNeeded()
    }

    private func setMeetingsUI(_ meetingsUI: MeetingsUI?, animated: Bool) {
        guard
            showMeetings,
            let meetingsNavigationController
        else {
            return
        }
        _meetingsUI = meetingsUI

        let viewControllers = [meetingsUI].compactMap(\.self)
        meetingsNavigationController.setViewControllers(viewControllers, animated: animated)
        meetingsNavigationController.view.layoutIfNeeded()
    }

    private func setSettingsUI(_ settingsUI: SettingsUI?, animated: Bool) {
        _settingsUI = settingsUI

        let viewControllers = [settingsUI].compactMap(\.self)
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }

    public func setConversationUI(_ conversationUI: ConversationUI?, animated: Bool) {
        // Before replacing the conversation, ensure the current one saves its draft
        if let currentConversation = _conversationUI {
            currentConversation.view.endEditing(true)
        }

        _conversationUI = conversationUI

        if conversationListUI == nil, conversationUI != nil {
            return assertionFailure("conversationListUI == nil, conversationUI != nil")
        }

        let viewControllers = [conversationListUI, conversationUI].compactMap(\.self)
        conversationListNavigationController.setViewControllers(viewControllers, animated: animated)
        conversationListNavigationController.view.layoutIfNeeded()
    }

    public func setSettingsContentUI(_ settingsContentUI: UIViewController?, animated: Bool) {
        _settingsContentUI = settingsContentUI

        if settingsUI == nil, settingsContentUI != nil {
            return assertionFailure("settingsUI == nil, settingsContentUI != nil")
        }

        let viewControllers = [settingsUI, settingsContentUI].compactMap(\.self)
        settingsNavigationController.setViewControllers(viewControllers, animated: animated)
        settingsNavigationController.view.layoutIfNeeded()
    }

    // MARK: - Files

    private func setFilesUI(
        _ filesUI: UIViewController?,
        animated: Bool
    ) {
        if filesNavigationController == nil {
            let filesNavigationController = UINavigationController()
            filesNavigationController.navigationBar.isTranslucent = false
            self.filesNavigationController = filesNavigationController
            viewControllers?.insert(filesNavigationController, at: 1)
            setupFilesTabBarItem()
        }

        _filesUI = filesUI

        let viewControllers = [filesUI].compactMap(\.self)
        filesNavigationController?.setViewControllers(viewControllers, animated: animated)
        filesNavigationController?.view.layoutIfNeeded()
    }

    private func setupFilesTabBarItem() {
        let tabBarItem = UITabBarItem(
            title: String(localized: "tabBar.files.title", bundle: .module),
            image: .init(systemName: "rectangle.stack"),
            selectedImage: .init(systemName: "rectangle.stack.fill")
        )
        tabBarItem.accessibilityIdentifier = "bottomBarFilesButton"
        tabBarItem.accessibilityLabel = String(
            localized: "tabBar.files.description",
            table: "Accessibility",
            bundle: .module
        )
        tabBarItem.accessibilityHint = String(
            localized: "tabBar.files.hint",
            table: "Accessibility",
            bundle: .module
        )
        filesNavigationController?.tabBarItem = tabBarItem
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarControllerPreview()
}
