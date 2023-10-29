// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation
import UIKit

extension ConversationListViewController: ConversationListTabBarControllerDelegate {

    func didChangeTab(with type: TabBarItemType) {

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        if let item = tabBar.items?.first(where: { $0.tag == type.rawValue }) {
            animateTabBarItem(item)
        }

        switch type {
        case .archive:
            setState(.archived, animated: true)
        case .startUI:
            presentPeoplePicker()
        case .folder:
            listContentController.listViewModel.folderEnabled = true
        case .list:
            listContentController.listViewModel.folderEnabled = false
        }
    }

    private func animateTabBarItem(_ item: UITabBarItem) {
        // Check if Reduce Motion is enabled in accessibility settings
        guard !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        tabBar.view(for: item)?.layer.add(createAnimation(), forKey: nil)
    }

    private func createAnimation() -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.05
        animation.duration = 0.2
        animation.autoreverses = true
        animation.damping = 1.0
        return animation
    }

}

extension UITabBar {
    func view(for item: UITabBarItem) -> UIView? {
        guard let items = items,
              let index = items.firstIndex(of: item),
              index < subviews.count
        else { return nil }

        var tabBarButtonViews: [UIView] = []

        for view in subviews {
            if let tabBarButtonClass = NSClassFromString("UITabBarButton"),
               view.isKind(of: tabBarButtonClass) {
                tabBarButtonViews.append(view)
            }
        }

        return tabBarButtonViews[safe: index]
    }

}
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
