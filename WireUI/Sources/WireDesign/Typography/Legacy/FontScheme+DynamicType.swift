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

extension UIFont {
    static func wr_preferredContentSizeMultiplier(for contentSizeCategory: UIContentSizeCategory) -> CGFloat {
        switch contentSizeCategory {
        case UIContentSizeCategory.accessibilityExtraExtraExtraLarge: 26.0 / 16.0
        case UIContentSizeCategory.accessibilityExtraExtraLarge: 25.0 / 16.0
        case UIContentSizeCategory.accessibilityExtraLarge: 24.0 / 16.0
        case UIContentSizeCategory.accessibilityLarge: 23.0 / 16.0
        case UIContentSizeCategory.accessibilityMedium: 22.0 / 16.0
        case UIContentSizeCategory.extraExtraExtraLarge: 22.0 / 16.0
        case UIContentSizeCategory.extraExtraLarge: 20.0 / 16.0
        case UIContentSizeCategory.extraLarge: 18.0 / 16.0
        case UIContentSizeCategory.large: 1.0
        case UIContentSizeCategory.medium: 15.0 / 16.0
        case UIContentSizeCategory.small: 14.0 / 16.0
        case UIContentSizeCategory.extraSmall: 13.0 / 16.0
        default:
            1.0
        }
    }
}
