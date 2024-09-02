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

enum L10n {
    enum Localizable {
        enum ConversationList {
            enum BottomBar {
                enum Contacts {
                    static let title = ""
                }
                enum Conversations {
                    static let title = ""
                }
                enum Folders {
                    static let title = ""
                }
                enum Archived {
                    static let title = ""
                }
            }
        }
    }
    enum Accessibility {
        enum TabBar {
            enum Contacts {
                static let description = ""
                static let hint = ""
            }
            enum Conversations {
                static let description = ""
                static let hint = ""
            }
            enum Folders {
                static let description = ""
                static let hint = ""
            }
            enum Archived {
                static let description = ""
                static let hint = ""
            }
        }
    }
}

enum MainTabBarControllerTab: Int, CaseIterable {

    case contacts, conversations, folders, archive

    @MainActor
    static func configuredTabBarController() -> UITabBarController {

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = .init(repeating: UINavigationController(), count: allCases.count)

        for tab in allCases {
            let tabBarItem: UITabBarItem
            switch tab {

            case .contacts:
                tabBarItem = .init(
                    title: L10n.Localizable.ConversationList.BottomBar.Contacts.title,
                    image: .init(resource: .contactsOutline),
                    selectedImage: .init(resource: .contactsFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarPlusButton"
                tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Contacts.description
                tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Contacts.hint

            case .conversations:
                tabBarItem = .init(
                    title: L10n.Localizable.ConversationList.BottomBar.Conversations.title,
                    image: .init(resource: .TabBar.conversations),
                    selectedImage: .init(resource: .TabBar.conversationsFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
                tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Conversations.description

            case .folders:
                tabBarItem = .init(
                    title: L10n.Localizable.ConversationList.BottomBar.Folders.title,
                    image: .init(resource: .foldersOutline),
                    selectedImage: .init(resource: .foldersFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarFolderListButton"
                tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Folders.description

            case .archive:
                tabBarItem = .init(
                    title: L10n.Localizable.ConversationList.BottomBar.Archived.title,
                    image: .init(resource: .archiveOutline),
                    selectedImage: .init(resource: .archiveFilled)
                )
                tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
                tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Archived.description
                tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Archived.hint

            }
            tabBarController.viewControllers[tab].tabBarItem = tabBarItem
        }
        return tabBarController
    }
}

@MainActor
func MainTabBarController(
    contacts: UIViewController,
    conversations: UIViewController,
    folders: UIViewController,
    archive: UIViewController
) -> UITabBarController {

    let mainTabBarController = MainTabBarControllerTab.configuredTabBarController()
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
