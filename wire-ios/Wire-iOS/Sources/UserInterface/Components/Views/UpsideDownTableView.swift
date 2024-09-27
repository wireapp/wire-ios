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

final class UpsideDownTableView: UITableView {
    // MARK: Lifecycle

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)

        UIView.performWithoutAnimation {
            self.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// The view that allow pan gesture to scroll the tableview
    weak var pannableView: UIView?

    var lockContentOffset = false

    var correctedContentInset: UIEdgeInsets {
        get {
            let insets = super.contentInset
            return UIEdgeInsets(top: insets.bottom, left: insets.left, bottom: insets.top, right: insets.right)
        }

        set {
            super.contentInset = UIEdgeInsets(
                top: newValue.bottom,
                left: newValue.left,
                bottom: newValue.top,
                right: newValue.right
            )
        }
    }

    override var contentOffset: CGPoint {
        get {
            super.contentOffset
        }

        set {
            // Blindly ignoring the SOLID principles, we are modifying the functionality of the parent class.
            if lockContentOffset {
                return
            }
            /// do not set contentOffset if the user is panning on the bottom edge of pannableView (with 10 pt
            /// threshold)
            if let pannableView,
               panGestureRecognizer.location(in: self.superview).y >= pannableView.frame.maxY - 10 {
                return
            }

            super.contentOffset = newValue
        }
    }

    override var tableHeaderView: UIView? {
        get {
            super.tableFooterView
        }

        set(tableHeaderView) {
            tableHeaderView?.transform = CGAffineTransform(scaleX: 1, y: -1)
            super.tableFooterView = tableHeaderView
        }
    }

    override var tableFooterView: UIView? {
        get {
            super.tableHeaderView
        }

        set(tableFooterView) {
            tableFooterView?.transform = CGAffineTransform(scaleX: 1, y: -1)
            super.tableHeaderView = tableFooterView
        }
    }

    override func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        let cell = super.dequeueReusableCell(withIdentifier: identifier)
        cell?.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }

    override func scrollToNearestSelectedRow(at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        super.scrollToNearestSelectedRow(at: inverseScrollPosition(scrollPosition), animated: animated)
    }

    override func scrollToRow(
        at indexPath: IndexPath,
        at scrollPosition: UITableView.ScrollPosition,
        animated: Bool
    ) {
        super.scrollToRow(at: indexPath, at: inverseScrollPosition(scrollPosition), animated: animated)
    }

    override func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        let cell = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        cell.transform = CGAffineTransform(scaleX: 1, y: -1)

        return cell
    }

    func inverseScrollPosition(_ scrollPosition: UITableView.ScrollPosition) -> UITableView.ScrollPosition {
        if scrollPosition == .top {
            .bottom
        } else if scrollPosition == .bottom {
            .top
        } else {
            scrollPosition
        }
    }
}
