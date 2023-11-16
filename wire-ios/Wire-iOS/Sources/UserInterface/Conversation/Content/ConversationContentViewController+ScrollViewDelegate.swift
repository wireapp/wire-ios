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

extension ConversationContentViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        removeHighlightsAndMenu()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dataSource.didScroll(tableView: scrollView as! UITableView)
        updateScrollToBottomButtonVisibility()
    }

    /// Updates the visibility of the `scrollToBottomButton`.
    ///
    /// This method checks the `isScrolledToBottom` property to determine whether the button should be hidden or shown.
    /// If the button's current visibility state is different from what it should be, it either directly sets the visibility
    /// or performs a fade in/out animation based on the user's accessibility settings for reduced motion.
    ///
    /// When "Reduce Motion" is enabled in accessibility settings, the button's visibility is changed without animation
    /// to respect the user's preference for reduced motion. Otherwise, a 0.25 second fade animation is used for
    /// a smoother transition between visible and hidden states.
    ///
    /// - Note: This method should be called whenever the scroll position changes, typically in response to a
    ///   `scrollViewDidScroll` event, to ensure that the button's visibility accurately reflects whether the
    ///   user is scrolled to the bottom of the content.
    func updateScrollToBottomButtonVisibility() {
        let shouldHideButton = isScrolledToBottom

        if scrollToBottomButton.isHidden != shouldHideButton {
            if UIAccessibility.isReduceMotionEnabled {
                self.scrollToBottomButton.alpha = shouldHideButton ? 0 : 1
                self.scrollToBottomButton.isHidden = shouldHideButton
            } else {
                UIView.animate(withDuration: 0.25, animations: {
                    self.scrollToBottomButton.alpha = shouldHideButton ? 0 : 1
                }) { _ in
                    self.scrollToBottomButton.isHidden = shouldHideButton
                }
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dataSource.scrollViewDidEndDecelerating(scrollView)
    }
}
