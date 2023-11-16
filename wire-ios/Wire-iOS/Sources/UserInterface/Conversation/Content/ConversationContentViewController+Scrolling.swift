//
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
import WireDataModel

extension ConversationContentViewController {

    func scroll(to message: ZMConversationMessage?, completion: ((UIView) -> Void)? = .none) {
        if let message = message {

            if message.hasBeenDeleted {
                presentAlertWithOKButton(message: "conversation.alert.message_deleted".localized)
            } else {
                dataSource.loadMessages(near: message) { index in

                    guard message.conversationLike === self.conversation else {
                        fatal("Message from the wrong conversation")
                    }

                    guard let indexToShow = index else {
                        return
                    }

                    self.tableView.scrollToRow(at: indexToShow, at: .top, animated: false)

                    if let cell = self.tableView.cellForRow(at: indexToShow) {
                        completion?(cell)
                    }
                }
            }
        } else {
            dataSource.loadMessages()
        }

        updateTableViewHeaderView()
    }

    /// Scrolls the tableView to the bottom-most row.
    ///
    /// This method checks if the tableView is not already scrolled to the bottom.
    /// If not, it loads new messages from the dataSource and scrolls to the bottom row.
    /// The scroll to the bottom is animated based on the user's accessibility settings
    /// and the number of messages. If reduce motion is enabled or the number of messages
    /// exceeds 20, the scroll animation is set to `.top`; otherwise, it's set to `.bottom`.
    /// After scrolling, the tableView's header view is updated.
    ///
    /// This method is typically called when the user taps the 'scroll to bottom' button.
    ///
    /// - Attention: This function is marked with `@objc` to allow it to be used as a selector for target-action
    ///   patterns, such as button taps.
    @objc
    func scrollToBottom() {
        guard !isScrolledToBottom else {
            print("scrollToBottom was called, but we're already at the bottom. No action taken.")
            return
        }

        dataSource.loadMessages()

        let lastRowIndexPath = IndexPath(row: 0, section: 0)
        let shouldAnimate = !UIAccessibility.isReduceMotionEnabled && dataSource.messages.count <= 20

        let scrollAnimation: UITableView.ScrollPosition = shouldAnimate ? .bottom : .top

        tableView.scrollToRow(at: lastRowIndexPath, at: scrollAnimation, animated: shouldAnimate)

        updateTableViewHeaderView()
    }
}
