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
import WireCommonComponents
import WireDataModel
import WireUIFoundation

extension StartUIViewController {
    var needsAddressBookPermission: Bool {
        let shouldSkip = AutomationHelper.sharedHelper.skipFirstLoginAlerts || userSession.selfUser.hasTeam
        return !AddressBookHelper.sharedHelper.isAddressBookAccessGranted && !shouldSkip
    }

    func presentShareContactsViewController() {
        let shareContactsViewController = ShareContactsViewController()
        shareContactsViewController.delegate = self
        navigationController?.pushViewController(shareContactsViewController, animated: true)
    }
}

// MARK: - StartUIViewController + ShareContactsViewControllerDelegate

extension StartUIViewController: ShareContactsViewControllerDelegate {
    func shareContactsViewControllerDidFinish(_ viewController: ShareContactsViewController) {
        viewController.dismiss(animated: true)
    }

    func shareContactsViewControllerDidSkip(_: ShareContactsViewController) {
        guard let tabBarController = presentingViewController as? UITabBarController else {
            return assertionFailure("wrong assumption!")
        }
        dismiss(animated: true) {
            // point to the contacts tab item
            var tabItemFrame = tabBarController.tabBar.bounds
            tabItemFrame.size.width /= CGFloat(tabBarController.tabBar.items?.count ?? 1)
            tabItemFrame.origin.x = CGFloat(MainTabBarController.Tab.contacts.rawValue) * tabItemFrame.size.width
            tabBarController.presentInviteActivityViewController(
                popoverPresentationConfiguration: .sourceView(
                    sourceView: tabBarController.tabBar,
                    sourceRect: tabItemFrame
                )
            )
        }
    }
}
