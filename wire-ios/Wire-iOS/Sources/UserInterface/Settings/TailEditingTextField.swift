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

/// @abstract The purpose of this subclass of UITextField is to give the possibility to edit the right-aligned text
/// field
/// with spaces. Default implementation collapses the trailing spaces as you type, which looks confusing. This control
/// can be used "as-is" without any additional configuration.
class TailEditingTextField: UITextField {

    private let isContextMenuAllowed: Bool
    
    init(frame: CGRect, isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func setup() {
        addTarget(
            self,
            action: #selector(TailEditingTextField.replaceNormalSpacesWithNonBreakingSpaces),
            for: UIControl.Event.editingDidBegin
        )
        addTarget(
            self,
            action: #selector(TailEditingTextField.replaceNormalSpacesWithNonBreakingSpaces),
            for: UIControl.Event.editingChanged
        )
        addTarget(
            self,
            action: #selector(TailEditingTextField.replaceNonBreakingSpacesWithNormalSpaces),
            for: UIControl.Event.editingDidEnd
        )
    }

    @objc
    func replaceNormalSpacesWithNonBreakingSpaces() {
        guard let isContainsNormalSpace = (text?.contains(String.breakingSpace)), isContainsNormalSpace else {
            return
        }

        text = text?.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
    }

    @objc
    func replaceNonBreakingSpacesWithNormalSpaces() {
        guard let isContainsNonBreakingSpace = (text?.contains(String.nonBreakingSpace)),
              isContainsNonBreakingSpace else { return }

        text = text?.replacingOccurrences(of: String.nonBreakingSpace, with: String.breakingSpace)
    }
}

extension TailEditingTextField {

    override func canPerformAction(
        _ action: Selector,
        withSender sender: Any?
    ) -> Bool {
        if !isContextMenuAllowed {
            let validActions = [
                #selector((any UIResponderStandardEditActions).select(_:)),
                #selector((any UIResponderStandardEditActions).selectAll(_:))
            ]
            return text!.isEmpty ? false : validActions.contains(action)
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
