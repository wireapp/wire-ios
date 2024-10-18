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

extension UIApplication {

    /// Get the top most view controller
    ///
    /// - Parameter onlyFullScreen: if false, also search for all kinds of presented view controller
    /// - Returns: the top most view controller
    func topmostViewController(onlyFullScreen: Bool = true) -> UIViewController? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let window = appDelegate.mainWindow,
              var topController = window.rootViewController else {
            return .none
        }

        while let presentedController = topController.presentedViewController,
              !onlyFullScreen || presentedController.modalPresentationStyle == .fullScreen {
            topController = presentedController
        }

        return topController
    }
}
