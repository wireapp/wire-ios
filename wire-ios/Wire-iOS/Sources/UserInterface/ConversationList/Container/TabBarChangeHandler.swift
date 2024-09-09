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
import WireUIFoundation

/// Responds to selected tab changes, ensuring the correct _principle_ tab is selected and `Contacts` or `Archive` views
/// are shown.
///
/// Currently we abuse our main `UITabBarController`. Two tabs (`Conversations` & `Folders`) contain
/// `ConversationListViewController` instances with real content. These are considered `PrincipleTab`s. The other two
/// tabs (`Contacts` & `Archive`) contain **empty** `UIViewController` instances. We use these empty tabs as buttons.
/// When either of these tabs are tapped we switch back to the currently selected _principle tab_ and request it to
/// present the corresponding `Contacts` or `Archive` view.
///
/// - Warning: This solution is only temporary and should be removed in the ongoing navigation overhaul. [WPB-6647]
final class TabBarChangeHandler: NSObject, UITabBarControllerDelegate {

    enum PrincipleTab {
        case conversations
        case folders
    }

    private let conversationsViewController: ConversationListViewController
    private let foldersViewController: ConversationListViewController
    private var principleTab: PrincipleTab

    /// Initializes a `TabBarChangeHandler`.
    /// - Parameters:
    ///   - conversationsViewController: The view controller corresponding the `Conversations` tab.
    ///   - foldersViewController: The view controller corresponding the `Folders` tab.
    ///   - selectedTab: The initially selected tab.
    init(
        conversationsViewController: ConversationListViewController,
        foldersViewController: ConversationListViewController,
        selectedTab: PrincipleTab
    ) {
        self.conversationsViewController = conversationsViewController
        self.foldersViewController = foldersViewController
        self.principleTab = selectedTab
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedIndex = MainTabBarController.Tab(rawValue: tabBarController.selectedIndex) else {
            fatalError("unexpected selected tab index")
        }

        switch selectedIndex {
        case .contacts:
            principleViewController.presentPeoplePicker { [self] in
                tabBarController.selectedIndex = principleTabIndex
            }
        case .conversations:
            principleTab = .conversations
        case .folders:
            principleTab = .folders
        case .archive:
            principleViewController.setState(.archived, animated: true) { [self] in
                tabBarController.selectedIndex = principleTabIndex
            }
        }
    }

    private var principleViewController: ConversationListViewController {
        switch principleTab {
        case .conversations:
            conversationsViewController
        case .folders:
            foldersViewController
        }
    }

    private var principleTabIndex: Int {
        switch principleTab {
        case .conversations:
            MainTabBarController.Tab.conversations.rawValue
        case .folders:
            MainTabBarController.Tab.folders.rawValue
        }
    }

}
