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

func MainTabBarController(
    contacts: UIViewController,
    conversations: UIViewController,
    folders: UIViewController,
    archive: UIViewController
) -> UITabBarController {

    let mainTabBarController = UITabBarController()
    mainTabBarController.viewControllers = [contacts, conversations, folders, archive]
    mainTabBarController.viewControllers?[0].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Contacts.title,
        image: .init(resource: .contactsOutline),
        selectedImage: .init(resource: .contactsFilled)
    )
    mainTabBarController.viewControllers?[0].tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
    mainTabBarController.viewControllers?[0].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Contacts.description
    mainTabBarController.viewControllers?[0].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Contacts.hint

    mainTabBarController.viewControllers?[1].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Conversations.title,
        image: .init(resource: .TabBar.conversations),
        selectedImage: .init(resource: .TabBar.conversationsFilled)
    )
    mainTabBarController.viewControllers?[1].tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
    mainTabBarController.viewControllers?[1].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Conversations.description

    mainTabBarController.viewControllers?[2].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Folders.title,
        image: .init(resource: .foldersOutline),
        selectedImage: .init(resource: .foldersFilled)
    )
    mainTabBarController.viewControllers?[2].tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
    mainTabBarController.viewControllers?[2].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Folders.description

    mainTabBarController.viewControllers?[3].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Archived.title,
        image: .init(resource: .archiveOutline),
        selectedImage: .init(resource: .archiveFilled)
    )
    mainTabBarController.viewControllers?[3].tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
    mainTabBarController.viewControllers?[3].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Archived.description
    mainTabBarController.viewControllers?[3].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Archived.hint

    mainTabBarController.selectedIndex = 1
    mainTabBarController.tabBar.backgroundColor = SemanticColors.View.backgroundDefault
    mainTabBarController.tabBar.unselectedItemTintColor = SemanticColors.Label.textTabBar

    return mainTabBarController
}

// MARK: - Previews

struct MainTabBarController_Previews: PreviewProvider {

    static var previews: some View {
        MainTabBarControllerWrapper()
    }
}

private struct MainTabBarControllerWrapper: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UITabBarController {
        MainTabBarController(
            contacts: TabItemViewController(placeholder: "Contacts"),
            conversations: TabItemViewController(placeholder: "Conversations"),
            folders: TabItemViewController(placeholder: "Folders"),
            archive: TabItemViewController(placeholder: "Archive")
        )
    }

    func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {}
}

private final class TabItemViewController: UIViewController {

    init(placeholder text: String) {
        super.init(nibName: nil, bundle: nil)

        let label = UILabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
