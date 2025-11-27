//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireSyncEngine

struct HorizontalMargins {
    var left: CGFloat
    var right: CGFloat
    var chatBubbleMinimumLeading: CGFloat
    var chatBubbleMinimumTrailing: CGFloat

    init(left: CGFloat, right: CGFloat, chatBubbleMinimumLeading: CGFloat, chatBubbleMinimumTrailing: CGFloat) {
        self.left = left
        self.right = right
        self.chatBubbleMinimumLeading = chatBubbleMinimumLeading
        self.chatBubbleMinimumTrailing = chatBubbleMinimumTrailing
    }

    init(userInterfaceSizeClass: UIUserInterfaceSizeClass) {
        switch userInterfaceSizeClass {
        case .regular:
            self.left = 56
            self.right = 16
            self.chatBubbleMinimumLeading = 136.0
            self.chatBubbleMinimumTrailing = 136.0
        default:
            self.left = 56
            self.right = 16
            self.chatBubbleMinimumLeading = 104.0
            self.chatBubbleMinimumTrailing = 72.0
        }
    }

    static func conversationHorizontalMargins(
        windowWidth: CGFloat? = UIApplication.shared.delegate?.window??.frame.width ?? UIScreen.main.bounds.width
    ) -> HorizontalMargins {
        let userInterfaceSizeClass: UIUserInterfaceSizeClass

            // On iPad 9.7 inch 2/3 mode, right view's width is 396pt, use the compact mode's narrower margin
            = if let windowWidth, windowWidth <= CGFloat.SplitView.IPadMarginLimit {
            .compact
        } else {
            .regular
        }

        return HorizontalMargins(userInterfaceSizeClass: userInterfaceSizeClass)
    }

}

extension UITraitEnvironment {
    var conversationHorizontalMargins: HorizontalMargins {
        HorizontalMargins.conversationHorizontalMargins()
    }

    var directionAwareConversationLayoutMargins: HorizontalMargins {
        let margins = conversationHorizontalMargins

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return HorizontalMargins(
                left: margins.right,
                right: margins.left,
                chatBubbleMinimumLeading: margins.chatBubbleMinimumTrailing,
                chatBubbleMinimumTrailing: margins.chatBubbleMinimumLeading
            )
        } else {
            return margins
        }
    }
}
