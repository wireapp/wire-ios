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

extension UIContentSizeCategory: @retroactive CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .unspecified:
            "unspecified"
        case .extraSmall:
            "extraSmall"
        case .small:
            "small"
        case .medium:
            "medium"
        case .large:
            "large"
        case .extraLarge:
            "extraLarge"
        case .extraExtraLarge:
            "extraExtraLarge"
        case .extraExtraExtraLarge:
            "extraExtraExtraLarge"
        case .accessibilityMedium:
            "accessibilityMedium"
        case .accessibilityLarge:
            "accessibilityLarge"
        case .accessibilityExtraLarge:
            "accessibilityExtraLarge"
        case .accessibilityExtraExtraLarge:
            "accessibilityExtraExtraLarge"
        case .accessibilityExtraExtraExtraLarge:
            "accessibilityExtraExtraExtraLarge"
        default:
            "unknown"
        }
    }
}
