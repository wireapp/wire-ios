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
import UserNotifications

// MARK: - ConversationListViewController + PermissionDeniedViewControllerDelegate

extension ConversationListViewController: PermissionDeniedViewControllerDelegate {
    func permissionDeniedViewControllerDidSkip(_: PermissionDeniedViewController) {
        closePushPermissionDeniedDialog()
    }

    func permissionDeniedViewControllerDidOpenNotificationSettings(_: PermissionDeniedViewController) {
        closePushPermissionDeniedDialog()
    }
}

extension ConversationListViewController {
    private func closePushPermissionDeniedDialog() {
        guard pushPermissionDeniedViewController === presentedViewController else {
            return assertionFailure()
        }

        dismiss(animated: true)
    }

    func showPermissionDeniedViewController() {
        let viewController = PermissionDeniedViewController.pushDeniedViewController()
        viewController.delegate = self
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
        pushPermissionDeniedViewController = viewController
    }
}
