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

import UIKit
import WireFoundation

// TODO: could typaliases take some of the generic conditions?

@MainActor
public final class MainCoordinator<SplitViewController, TabBarController, NewConversationBuilder>: MainCoordinatorProtocol, UISplitViewControllerDelegate where
    SplitViewController: MainSplitViewControllerProtocol,
    TabBarController: MainTabBarControllerProtocol,
    SplitViewController.Sidebar: MainSidebarProtocol,
    SplitViewController.ConversationList == TabBarController.ConversationList,
    TabBarController.Archive == UIViewController,
NewConversationBuilder: MainContentViewControllerBuilder {

    private weak var mainSplitViewController: SplitViewController!
    private weak var mainTabBarController: TabBarController!

    /// A reference to the archived conversations view controller. This property is needed for the expanded layout mode
    /// when the archived conversations list is taken out of the tab bar controller and presented on top of the conversation list.
    private weak var archivedConversations: TabBarController.Archive?

    /// A reference to the settings view controller. This property is needed for the expanded layout mode
    /// when the settings is taken out of the tab bar controller and presented on top of the conversation list.
    private var settings: TabBarController.Settings?

    private let newConversationBuilder: NewConversationBuilder

    private var selfProfileBuilder: any ViewControllerBuilder
    private weak var selfProfileViewController: UIViewController?

    private var isLayoutCollapsed = false

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        newConversationBuilder: NewConversationBuilder,
        selfProfileBuilder: /* some */ any ViewControllerBuilder
    ) {
        self.mainSplitViewController = mainSplitViewController
        self.mainTabBarController = mainTabBarController
        self.newConversationBuilder = newConversationBuilder
        self.selfProfileBuilder = selfProfileBuilder

        archivedConversations = mainTabBarController.archive
        settings = mainTabBarController.settings
    }

    deinit {
        /* WireLogger.ui.debug */ print("MainCoordinator.deinit")
    }

    // MARK: - Methods

    public func showConversationList(conversationFilter: TabBarController.ConversationList.ConversationFilter?) {
        showConversationList()

        switch conversationFilter {
        case .none:
            mainSplitViewController.conversationList?.conversationFilter = .none
        case .favorites:
            mainSplitViewController.conversationList?.conversationFilter = .favorites
        case .groups:
            mainSplitViewController.conversationList?.conversationFilter = .groups
        case .oneOnOne:
            mainSplitViewController.conversationList?.conversationFilter = .oneOnOne
        default:
            break
        }
    }

    public func showConversationList() {
        mainTabBarController.selectedContent = .conversations

        if !isLayoutCollapsed {
            moveArchivedConversationsIntoMainTabBarControllerIfNeeded()

            // TODO: complete
            // settings visible?
            // archive visible?
            // selfProfile visible?
        }
    }

    public func showArchivedConversations() {
        mainTabBarController.selectedContent = .archive

        if !isLayoutCollapsed {
            // if it's already visible (and not contained in the tabBarController anymore), do nothing
            guard mainTabBarController.archive != nil else { return }
            addArchivedConversationsAsChildOfConversationList()
        }
    }

    public func showSelfProfile() {
        guard selfProfileViewController == nil else {
            return assertionFailure() // TODO: inject logger instead
        }

        let selfProfileViewController = UINavigationController(rootViewController: selfProfileBuilder.build())
        selfProfileViewController.modalPresentationStyle = .formSheet
        self.selfProfileViewController = selfProfileViewController

        let conversationList = if isLayoutCollapsed {
            mainTabBarController.conversations!.conversationList
        } else {
            mainSplitViewController.conversationList!
        }
        conversationList.present(selfProfileViewController, animated: true)
    }

    public func showSettings() {
        mainTabBarController.selectedContent = .settings

        if !isLayoutCollapsed {
            // if it's already visible (and not contained in the tabBarController anymore), abort
            //guard mainTabBarController.settings != nil else { return }
            //addSettingsAsChildOfConversationList()

            // TODO: remove this workaround
            let settingsViewController = (mainTabBarController.settings ?? settings)!
            mainTabBarController.settings = nil
            let navigationController = UINavigationController(rootViewController: settingsViewController)
            navigationController.modalPresentationStyle = .formSheet

            // TODO: try to get rid of this line
            navigationController.view.backgroundColor = .systemBackground

            settings = settingsViewController

            let conversationList = if isLayoutCollapsed {
                mainTabBarController.conversations!.conversationList
            } else {
                mainSplitViewController.conversationList!
            }
            conversationList.present(navigationController, animated: true)
        }

        return;

        fatalError("not implemented yet")

        //        private func createSettingsViewController() -> UIViewController {
        //            let settingsViewControllerBuilder = SettingsMainViewControllerBuilder(
        //                userSession: userSession,
        //                selfUser: userSession.selfUserLegalHoldSubject
        //            )
        //            return settingsViewControllerBuilder.build()
        //        }

        // TODO: remove?
        // guard let selfUser = ZMUser.selfUser() else {
        //     assertionFailure("ZMUser.selfUser() is nil")
        //     return
        // }

        //        let settingsViewController = createSettingsViewController(selfUser: selfUser)
        //        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: settingsViewController)

        // TODO: fix
        fatalError("TODO")
        // if wr_splitViewController?.layoutSize == .compact {
        //     present(keyboardAvoidingViewController, animated: true)
        // } else {
        //     keyboardAvoidingViewController.modalPresentationStyle = .formSheet
        //     keyboardAvoidingViewController.view.backgroundColor = .black
        //     present(keyboardAvoidingViewController, animated: true)
        // }
    }

    public func showNewConversation() {
        let viewController = newConversationBuilder.build(mainCoordinator: self)

        let navigationController = UINavigationController(rootViewController: viewController)
        // navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController.modalPresentationStyle = .formSheet
        // newConversationViewController = navigationController

        if isLayoutCollapsed {
            mainTabBarController.conversations!.conversationList.present(navigationController, animated: true)
        } else {
            mainSplitViewController.conversationList!.present(navigationController, animated: true)
        }
    }

    //    public func openConversation(
    //        _ conversation: Conversation,
    //        focusOnView focus: Bool,
    //        animated: Bool
    //    ) {
    //        fatalError("not implemented yet")
    //    }
    //
    //    public func openConversation(
    //        _ conversation: Conversation,
    //        andScrollTo message: ConversationMessage,
    //        focusOnView focus: Bool,
    //        animated: Bool
    //    ) {
    //        fatalError("not implemented yet")
    //    }

    // TODO: add a doc comment describing the approach having navigation controllers for presenting the navigation bar and for the possibility to move view controllers

    // MARK: - UISplitViewControllerDelegate

    // func splitViewController(
    //     _ svc: UISplitViewController,
    //     topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    // ) -> UISplitViewController.Column {
    //     //
    // }

    // func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
    //     print("349ur09e willHide \(column)")
    // }

    public func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = true

        // move view controllers from the split view controller's columns to the tab bar controller
        let conversationListViewController = mainSplitViewController.conversationList!
        mainSplitViewController.conversationList = nil
        mainTabBarController.conversations = (conversationListViewController, nil)
        conversationListViewController.splitViewInterface = .collapsed

        // TODO: conversations

        // move the archived conversations list back to the tab bar controller if needed
        moveArchivedConversationsIntoMainTabBarControllerIfNeeded()

        // move the settings back to the tab bar controller if needed
        moveSettingsIntoMainTabBarControllerIfNeeded()
    }

    // func splitViewController(
    //     _ svc: UISplitViewController,
    //     displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
    // ) -> UISplitViewController.DisplayMode {
    //     //
    // }

    // func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {
    //     print("349ur09e willShow \(column)")
    // }

    public func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = false

        // move view controllers from the tab bar controller to the supplementary column
        let (conversationViewController, _) = mainTabBarController.conversations!
        mainTabBarController.conversations = nil
        mainSplitViewController.conversationList = conversationViewController
        conversationViewController.splitViewInterface = .expanded

        // TODO: conversations

        // if the archived conversations view controller was visible, present it on top of the conversation list
        if mainTabBarController.selectedContent == .archive {
            addArchivedConversationsAsChildOfConversationList()
            mainSplitViewController.sidebar.conversationFilter = .archived
        }

        // if the settings view controller was visible, present it // TODO: on top of the conversation list
        if mainTabBarController.selectedContent == .settings {
            //addSettingsAsChildOfConversationList()
            //mainSplitViewController.sidebar.selectedMenuItem = .settings

            // TODO: remove this workaround
            settings = mainTabBarController.settings!
            mainTabBarController.settings = nil

            let navigationController = UINavigationController(rootViewController: settings!)
            navigationController.modalPresentationStyle = .formSheet

            // TODO: try to get rid of this line
            navigationController.view.backgroundColor = .systemBackground

            mainSplitViewController.conversationList!.present(navigationController, animated: false)
        }
    }

    // MARK: - Helpers

    private func addArchivedConversationsAsChildOfConversationList() {
        let archivedConversations = archivedConversations!
        mainTabBarController.archive = nil
        addViewControllerAsChildOfConversationList(archivedConversations)
    }

    /*
    private func addSettingsAsChildOfConversationList() {
        let settings = settings!
        mainTabBarController.archive = nil
        addViewControllerAsChildOfConversationList(settings)
    }
     */

    private func addViewControllerAsChildOfConversationList(_ viewController: UIViewController) {
        let conversationList = mainSplitViewController.conversationList!
        conversationList.addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        conversationList.view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: conversationList.view.leadingAnchor),
            viewController.view.topAnchor.constraint(equalTo: conversationList.view.topAnchor),
            conversationList.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            conversationList.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        viewController.didMove(toParent: conversationList)
    }

    private func moveArchivedConversationsIntoMainTabBarControllerIfNeeded() {
        // If the archive tab is empty, we're showing the conversation archive in the expanded layout.
        // No need to move it back.
        if mainTabBarController.archive == nil {
            archivedConversations!.willMove(toParent: nil)
            archivedConversations!.view.removeFromSuperview()
            archivedConversations!.removeFromParent()
            archivedConversations!.view.translatesAutoresizingMaskIntoConstraints = true
            mainTabBarController.archive = archivedConversations
            mainTabBarController.selectedContent = .archive
        }
    }

    private func moveSettingsIntoMainTabBarControllerIfNeeded() {
        // If the settings tab is empty, we're showing the settings in the expanded layout.
        // No need to move it back.
        if mainTabBarController.settings == nil {
            settings!.willMove(toParent: nil)
            settings!.view.removeFromSuperview()
            settings!.removeFromParent()
            settings!.view.translatesAutoresizingMaskIntoConstraints = true
            mainTabBarController.settings = settings
            mainTabBarController.selectedContent = .settings
        }
    }
}
