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
import WireMainNavigationUI

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

extension StartUIViewController: ShareContactsViewControllerDelegate {

    func shareContactsViewControllerDidFinish(_ viewController: ShareContactsViewController) {
        // called once user has given its contact permission

        if let navigationController = viewController.navigationController {
            var viewControllers = navigationController.viewControllers
            _ = viewControllers.popLast()
            viewControllers.append(ContactsViewController(isFederationUsageAllowed: userSession.isFederationUsageAllowed))
            navigationController.setViewControllers(viewControllers, animated: true)
        } else {
            viewController.dismiss(animated: true) {
                self.inviteMoreButtonTapped(nil)
            }
        }
    }

    func shareContactsViewControllerDidSkip(_ viewController: ShareContactsViewController) {
        guard
            let navigationController,
            let sourceView = quickActionsBar.inviteButton?.superview,
            let sourceRect = quickActionsBar.inviteButton?.frame.insetBy(dx: -2, dy: -2)
        else { return }

        navigationController.popViewController(animated: true) { [weak self] in
            self?.presentInviteActivityViewController(
                popoverPresentationConfiguration: .sourceView(sourceView, sourceRect),
                completionWithItemsHandler: { _, _, _, _ in self?.dismiss(animated: true) }
            )
        }
    }
}
