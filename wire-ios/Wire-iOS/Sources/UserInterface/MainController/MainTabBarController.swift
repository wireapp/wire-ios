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

enum MainTabBarControllerTab: Int {
    case conversations, archive, settings
}

func MainTabBarController(
    conversations: UIViewController,
    archive: UIViewController,
    settings: UIViewController
) -> UITabBarController {

    let tabBarItemAppearance = UITabBarItemAppearance()
    tabBarItemAppearance.normal.iconColor = .brown
    tabBarItemAppearance.selected.iconColor = .cyan

    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithDefaultBackground()
    tabBarAppearance.shadowImage = .from(solidColor: ColorTheme.Strokes.outline)
    tabBarAppearance.backgroundColor = ColorTheme.Backgrounds.background
    tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance

    let mainTabBarController = UITabBarController()
    mainTabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
    mainTabBarController.viewControllers = [conversations, archive, settings]

    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Conversations.title,
        image: .init(resource: .TabBar.conversations),
        selectedImage: .init(resource: .TabBar.conversationsFilled)
    )
    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem.accessibilityIdentifier = "bottomBarRecentListButton"
    mainTabBarController.viewControllers?[tab: .conversations].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Conversations.description

    mainTabBarController.viewControllers?[tab: .archive].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Archived.title,
        image: .init(resource: .TabBar.archive),
        selectedImage: .init(resource: .TabBar.archiveFilled)
    )
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityIdentifier = "bottomBarArchivedButton"
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Archived.description
    mainTabBarController.viewControllers?[tab: .archive].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Archived.hint

    mainTabBarController.viewControllers?[tab: .settings].tabBarItem = .init(
        title: L10n.Localizable.ConversationList.BottomBar.Settings.title,
        image: .init(resource: .TabBar.settings),
        selectedImage: .init(resource: .TabBar.settingsFilled)
    )
    mainTabBarController.viewControllers?[tab: .settings].tabBarItem.accessibilityIdentifier = "bottomBarSettingsButton"
    mainTabBarController.viewControllers?[tab: .settings].tabBarItem.accessibilityLabel = L10n.Accessibility.TabBar.Settings.description
    mainTabBarController.viewControllers?[tab: .settings].tabBarItem.accessibilityHint = L10n.Accessibility.TabBar.Settings.hint

    mainTabBarController.selectedIndex = MainTabBarControllerTab.conversations.rawValue
    mainTabBarController.tabBar.unselectedItemTintColor = .yellow

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
            conversations: tabItem(BottomBar.Conversations.title),
            archive: tabItem(BottomBar.Archived.title),
            settings: tabItem(BottomBar.Settings.title)
        )
    }

    func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {}
}

// TODO: remove duplicated code

extension UIImage {

    fileprivate static func from(solidColor color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
