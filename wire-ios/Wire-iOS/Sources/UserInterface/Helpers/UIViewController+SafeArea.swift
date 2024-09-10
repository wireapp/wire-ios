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

extension UIView {

    @available(*, deprecated, message: "Will be removed")
    var safeTopAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.topAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.centerYAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeCenterXAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.centerXAnchor
    }
}
