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

public extension UITabBarController {

    /// Sets colors so that this instance looks like the `MainTabBarController` should look like.
    func applyMainTabBarControllerAppearance() {
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = ColorTheme.Base.secondaryText
        tabBarItemAppearance.normal.titleTextAttributes[.foregroundColor] = ColorTheme.Base.secondaryText

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = ColorTheme.Backgrounds.background
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance

        tabBar.backgroundColor = ColorTheme.Backgrounds.background
        tabBar.unselectedItemTintColor = ColorTheme.Base.secondaryText
        tabBar.standardAppearance = tabBarAppearance
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainTabBarControllerAppearancePreview()
}

@MainActor
func MainTabBarControllerAppearancePreview() -> UIViewController {
    let systemNames = ["eraser", "highlighter", "trash", "lasso"]
    let colors = [UIColor.green, .orange, .red, .yellow]

    let tabBarController = UITabBarController()
    tabBarController.viewControllers = (0 ..< 4).map { index in
        let viewController = UIViewController()
        viewController.view.backgroundColor = colors[index]
        viewController.tabBarItem.image = .init(systemName: systemNames[index])
        viewController.tabBarItem.title = systemNames[index]
        return viewController
    }
    tabBarController.selectedIndex = 1
    tabBarController.applyMainTabBarControllerAppearance()
    return tabBarController
}
