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

extension UIModalPresentationStyle: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .fullScreen:
            "fullScreen"
        case .pageSheet:
            "pageSheet"
        case .formSheet:
            "formSheet"
        case .currentContext:
            "currentContext"
        case .custom:
            "custom"
        case .overFullScreen:
            "overFullScreen"
        case .overCurrentContext:
            "overCurrentContext"
        case .popover:
            "popover"
        case .blurOverFullScreen:
            "blurOverFullScreen"
        case .none:
            "none"
        case .automatic:
            "automatic"
        @unknown default:
            "unknown"
        }
    }
}
