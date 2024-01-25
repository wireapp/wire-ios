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

import UIKit

extension UIApplication {

    /// Check whether that app is in left to right layout.
    static var isLeftToRightLayout: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }

}

// MARK: - UIEdgeInsets

extension UIEdgeInsets {

    /// The leading insets, that respect the layout direction.
    var leading: CGFloat {
        if UIApplication.isLeftToRightLayout {
            return left
        } else {
            return right
        }
    }

    /// The trailing insets, that respect the layout direction.
    var trailing: CGFloat {
        if UIApplication.isLeftToRightLayout {
            return right
        } else {
            return left
        }
    }
}

// MARK: - String

extension String {

    func addingTrailingAttachment(_ attachment: NSTextAttachment, verticalOffset: CGFloat = 0) -> NSAttributedString {
        if let attachmentSize = attachment.image?.size {
            attachment.bounds = CGRect(x: 0, y: verticalOffset, width: attachmentSize.width, height: attachmentSize.height)
        }

        if UIApplication.isLeftToRightLayout {
            return self + "  " + NSAttributedString(attachment: attachment)
        } else {
            return NSAttributedString(attachment: attachment) + "  " + self
        }
    }
}
