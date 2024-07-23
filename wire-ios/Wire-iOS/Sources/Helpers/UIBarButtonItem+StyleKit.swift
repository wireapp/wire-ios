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
import WireCommonComponents
import WireDesign

extension UIBarButtonItem {

    typealias IconColors = SemanticColors.Icon

    convenience init(icon: StyleKitIcon,
                     style: UIBarButtonItem.Style = .plain,
                     target: Any?,
                     action: Selector?) {
        self.init(
            image: icon.makeImage(size: .tiny,
                                  color: IconColors.foregroundDefaultBlack),
            style: style,
            target: target,
            action: action
        )
    }

    static func createNavigationRightBarButtonItem(
        title: String? = nil,
        systemImage: Bool,
        target buttonTarget: Any?,
        action buttonAction: Selector?,
        font buttonFont: UIFont = .preferredFont(forTextStyle: .body)) -> UIBarButtonItem {

            var rightBarButtonItem: UIBarButtonItem
            if systemImage {
                rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .done,
                    target: buttonTarget,
                    action: buttonAction)
            } else {
                rightBarButtonItem = UIBarButtonItem(
                    title: title,
                    style: .plain,
                    target: buttonTarget,
                    action: buttonAction)
            }

            let buttonStates: [UIControl.State] = [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved]

            buttonStates.forEach { buttonState in
                rightBarButtonItem.setTitleTextAttributes(
                    [NSAttributedString.Key.font: buttonFont],
                    for: buttonState)
            }
            return rightBarButtonItem

        }

}
