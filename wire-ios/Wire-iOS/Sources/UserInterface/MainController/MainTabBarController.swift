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

enum MainTabBarControllerTab: Int {
    case contacts, conversations, folders, archive
}

func MainTabBarController(
    contacts: UIViewController,
    conversations: UIViewController,
    folders: UIViewController,
    archive: UIViewController
) -> UITabBarController {

    let mainTabBarController = UITabBarController()
    mainTabBarController.viewControllers = [contacts, conversations, folders, archive]
    mainTabBarController.viewControllers?[tab: .contacts].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Contacts.title,
        image: .init(resource: .contactsOutline),
        selectedImage: .init(resource: .contactsFilled)
    )
    mainTabBarController.viewControllers?[tab: .contacts].tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
    mainTabBarController.viewControllers?[tab: .contacts].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Contacts.description
    mainTabBarController.viewControllers?[tab: .contacts].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Contacts.hint

    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Conversations.title,
        image: .init(resource: .TabBar.conversations),
        selectedImage: .init(resource: .TabBar.conversationsFilled)
    )
    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Conversations.description

    mainTabBarController.viewControllers?[tab: .folders].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Folders.title,
        image: .init(resource: .foldersOutline),
        selectedImage: .init(resource: .foldersFilled)
    )
    mainTabBarController.viewControllers?[tab: .folders].tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
    mainTabBarController.viewControllers?[tab: .folders].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Folders.description

    mainTabBarController.viewControllers?[tab: .archive].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Archived.title,
        image: .init(resource: .archiveOutline),
        selectedImage: .init(resource: .archiveFilled)
    )
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Archived.description
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Archived.hint

    mainTabBarController.selectedIndex = MainTabBarControllerTab.conversations.rawValue
    mainTabBarController.tabBar.backgroundColor = SemanticColors.View.backgroundDefault
    mainTabBarController.tabBar.unselectedItemTintColor = SemanticColors.Label.textTabBar

    return mainTabBarController
}

// MARK: -

extension Array where Element == UIViewController {

    fileprivate subscript(tab tab: MainTabBarControllerTab) -> Element {
        get { self[tab.rawValue] }
        set { self[tab.rawValue] = newValue }
    }
}

// MARK: - Previews

struct MainTabBarController_Previews: PreviewProvider {

    static var previews: some View {
        MainTabBarControllerWrapper()
            .ignoresSafeArea(edges: .all)
    }
}

private struct MainTabBarControllerWrapper: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UITabBarController {
        typealias BottomBar = L10n.Localizable.ConversationList.BottomBar
        let tabItem: (String) -> UIHostingController = { .init(rootView: Text($0)) }
        return MainTabBarController(
            contacts: tabItem(BottomBar.Contacts.title),
            conversations: tabItem(BottomBar.Conversations.title),
            folders: tabItem(BottomBar.Folders.title),
            archive: tabItem(BottomBar.Archived.title)
        )
    }

    func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {}
}
