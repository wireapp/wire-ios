//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Foundation
import UIKit

extension UIView {

    func fadeIn(
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0.0,
        completion: @escaping ((Bool) -> Void) = { _ in }
    ) {
        isHidden = true
        alpha = 0
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: {
            self.isHidden = false
            self.alpha = 1.0
        }, completion: completion)  }

    func fadeOut(
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0.0,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        isHidden = false
        alpha = 1
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: {
            self.isHidden = true
            self.alpha = 0.0
        }, completion: completion)
    }
}
