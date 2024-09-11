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

extension UIScreen {

    @available(*, deprecated, message: "Use `safeAreaInsets` of UIView.")
    static var safeArea: UIEdgeInsets {
        if hasNotch {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                return appDelegate.mainWindow?.safeAreaInsets ?? UIEdgeInsets.zero
            }
        }
        return UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    }

    @available(*, deprecated, message: "Will be removed")
    static var hasBottomInset: Bool {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let window = appDelegate.mainWindow {
            let insets = window.safeAreaInsets
            return insets.bottom > 0
        }
        return false
    }

    @available(*, deprecated, message: "Will be removed")
    static var hasNotch: Bool {
        // On iOS12 insets.top == 20 on devices without a notch.
        // insets.top == 44 on devices with a notch.
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let window = appDelegate.mainWindow {
            let insets = window.safeAreaInsets
            return insets.top > 20 || insets.bottom > 0
        }
        return false
    }

    @available(*, deprecated, message: "Will be removed")
    var isCompact: Bool {
        return bounds.size.height <= 568
    }
}
