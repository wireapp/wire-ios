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

/// A UITextField subclass that provides centralized control over context menu actions
/// such as copy, paste, select, select all, and the AutoFill menu.
///
/// Use `isContextMenuAllowed` to enable or restrict specific actions.
/// This base class is designed to be subclassed by custom UITextField implementations
/// that require consistent context menu behavior across the app.
class ContextMenuControllableTextField: UITextField {

    private let isContextMenuAllowed: Bool

    init(frame: CGRect, isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed

        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(
        _ action: Selector,
        withSender sender: Any?
    ) -> Bool {
        if !isContextMenuAllowed {
            let validActions: [Selector] = [
                #selector((UIResponderStandardEditActions).select(_:)),
                #selector((UIResponderStandardEditActions).selectAll(_:))
            ]
            return !(text?.isEmpty ?? true) && validActions.contains(action)
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override func buildMenu(with builder: any UIMenuBuilder) {
        if !isContextMenuAllowed {
            if #available(iOS 17.0, *) {
                builder.remove(menu: .autoFill)
            }
        }
    }

}
