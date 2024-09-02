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

public enum MainTabBarControllerTab: Int, CaseIterable {

    case contacts, conversations, folders, archive

    /// Creates a new instance of `UITabBarController` and configures its `viewControllers` based
    /// on `MainTabBarControllerTab`'s cases. Each tab is a `UINavigationController` instance.
    @MainActor
    public static func configuredTabBarController() -> UITabBarController {

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = allCases.map { _ in UINavigationController() }

        for tab in allCases {
            let tabBarItem: UITabBarItem
            switch tab {

            case .contacts:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.contacts.title", bundle: .module, comment: ""),
                    image: .init(resource: .Temp.contactsOutline),
                    selectedImage: .init(resource: .Temp.contactsFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.contacts.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.contacts.hint", bundle: .module, comment: "")

            case .conversations:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.conversations.title", bundle: .module, comment: ""),
                    image: .init(resource: .TabBar.conversations),
                    selectedImage: .init(resource: .TabBar.conversationsFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.conversations.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.conversations.hint", bundle: .module, comment: "")

            case .folders:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.folders.title", bundle: .module, comment: ""),
                    image: .init(resource: .Temp.foldersOutline),
                    selectedImage: .init(resource: .Temp.foldersFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.folders.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.folders.hint", bundle: .module, comment: "")

            case .archive:
                tabBarItem = .init(
                    title: NSLocalizedString("tabBar.archived.title", bundle: .module, comment: ""),
                    image: .init(resource: .TabBar.archive),
                    selectedImage: .init(resource: .TabBar.archiveFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = NSLocalizedString("tabBar.archived.description", bundle: .module, comment: "")
                tabBarItem.accessibilityHint = NSLocalizedString("tabBar.archived.hint", bundle: .module, comment: "")

            }
            tabBarController.viewControllers[tab].tabBarItem = tabBarItem
        }
        return tabBarController
    }
}

// TODO: remvoe
@MainActor
public func MainTabBarController(
    contacts: UIViewController,
    conversations: UIViewController,
    folders: UIViewController,
    archive: UIViewController
) -> UITabBarController {

    let mainTabBarController = MainTabBarControllerTab.configuredTabBarController()
    // TODO: wrap in navigation controller
    mainTabBarController.viewControllers[.contacts].viewControllers = [contacts]
    mainTabBarController.viewControllers[.conversations].viewControllers = [conversations]
    mainTabBarController.viewControllers[.folders].viewControllers = [folders]
    mainTabBarController.viewControllers[.archive].viewControllers = [archive]

    MainTabBarControllerAppearance().apply(mainTabBarController)

    return mainTabBarController
}

// MARK: -

private extension Optional where Wrapped == Array<UIViewController> {

    subscript(tab: MainTabBarControllerTab) -> UINavigationController {
        get { self![tab.rawValue] as! UINavigationController }
        set { self![tab.rawValue] = newValue }
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
        let tabItem: (String) -> UIHostingController = { .init(rootView: Text($0)) }
        return MainTabBarController(
            contacts: tabItem(NSLocalizedString("tabBar.contacts.title", bundle: .module, comment: "")),
            conversations: tabItem(NSLocalizedString("tabBar.conversations.title", bundle: .module, comment: "")),
            folders: tabItem(NSLocalizedString("tabBar.folders.title", bundle: .module, comment: "")),
            archive: tabItem(NSLocalizedString("tabBar.archived.title", bundle: .module, comment: ""))
        )
    }

    func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {}
}
