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

struct HorizontalMargins {

    var leading: CGFloat
    var trailing: CGFloat

    @available(*, deprecated, renamed: "leading")
    var left: CGFloat { leading }
    @available(*, deprecated, renamed: "trailing")
    var right: CGFloat { trailing }

    fileprivate init(leading: CGFloat, trailing: CGFloat) {
        self.leading = leading
        self.trailing = trailing
    }

    init(userInterfaceSizeClass: UIUserInterfaceSizeClass) {
        switch userInterfaceSizeClass {
        case .regular:
            self.leading = 96
            self.trailing = 96
        default:
            self.leading = 56
            self.trailing = 16
        }
    }
}

extension UITraitEnvironment {
    var conversationHorizontalMargins: HorizontalMargins {
        conversationHorizontalMargins()
    }

    func conversationHorizontalMargins(
        windowWidth: CGFloat? = UIApplication.shared.delegate?.window??.frame
            .width ?? UIScreen.main.bounds.width
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

    var directionAwareConversationLayoutMargins: HorizontalMargins {
        let margins = conversationHorizontalMargins

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return HorizontalMargins(leading: margins.trailing, trailing: margins.leading)
        } else {
            return margins
        }
    }
}
