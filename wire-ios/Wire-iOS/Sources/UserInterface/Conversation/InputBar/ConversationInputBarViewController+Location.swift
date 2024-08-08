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

import Foundation
import WireSyncEngine

extension ConversationInputBarViewController {
    @objc
    func locationButtonPressed(_ sender: IconButton) {
        let checker = PrivacyWarningChecker(conversation: conversation) {
            self.showLocationSelection(from: sender)
        }
        checker.performAction()
    }

    private func showLocationSelection(from sender: IconButton) {
        guard let parentViewController = self.parent else { return }

        let locationSelectionViewController = LocationSelectionViewController()
        locationSelectionViewController.modalPresentationStyle = .popover

        if let popover = locationSelectionViewController.popoverPresentationController {
            popover.sourceView = sender.superview!
            popover.sourceRect = sender.frame.insetBy(dx: -4, dy: -4)
        }

        locationSelectionViewController.title = conversation.displayName
        locationSelectionViewController.delegate = self
        parentViewController.present(locationSelectionViewController, animated: true)
    }
}

extension ConversationInputBarViewController: LocationSelectionViewControllerDelegate {

    func locationSelectionViewController(_ viewController: LocationSelectionViewController, didSelectLocationWithData locationData: LocationData) {
        guard let conversation = conversation as? ZMConversation else { return }

        userSession.enqueue {
            do {
                try conversation.appendLocation(with: locationData)
                Analytics.shared.tagMediaActionCompleted(.location, inConversation: conversation)
            } catch {
                Logging.messageProcessing.warn("Failed to append location message. Reason: \(error.localizedDescription)")
            }
        }

        parent?.dismiss(animated: true)
    }

    func locationSelectionViewControllerDidCancel(_ viewController: LocationSelectionViewController) {
        parent?.dismiss(animated: true)
    }
}
