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

    /// Show or hide the scroll to bottom button for the current scroll position.
    func updateScrollToBottomButtonVisibility() {
        let shouldHideButton = isScrolledToBottom

        if scrollToBottomButton.isHidden != shouldHideButton {
            if UIAccessibility.isReduceMotionEnabled {
                scrollToBottomButton.isHidden = shouldHideButton
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
