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

// TODO: [WPB-8778] remove the whole file

extension UIViewController {
    @available(*, deprecated, message: "Will be removed")
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        return self.view.safeAreaLayoutGuide.bottomAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeTopAnchor: NSLayoutYAxisAnchor {
        return self.view.safeAreaLayoutGuide.topAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        return view.safeAreaLayoutGuide.centerYAnchor
    }
}

extension UIView {
    @available(*, deprecated, message: "Will be removed")
    var safeAreaLayoutGuideOrFallback: UILayoutGuide {
        return safeAreaLayoutGuide
    }

    @available(*, deprecated, message: "Will be removed")
    var safeAreaInsetsOrFallback: UIEdgeInsets {
        return safeAreaInsets
    }

    @available(*, deprecated, message: "Will be removed")
    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.leadingAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.trailingAnchor
    }

    @available(*, deprecated, message: "Will be removed")
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.bottomAnchor
    }

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
