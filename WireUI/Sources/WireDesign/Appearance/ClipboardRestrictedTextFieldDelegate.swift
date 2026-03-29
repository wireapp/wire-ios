//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

/// A `UITextFieldDelegate` that restricts the edit menu (copy/paste/cut) on
/// system-created text fields that cannot be subclassed, such as those inside
/// `UIAlertController` or `UISearchBar`.
///
/// Supports two modes:
/// - **Standalone**: for text fields with no existing delegate.
/// - **Proxy**: for text fields with an internal delegate (e.g. `UISearchBar.searchTextField`);
///   transparently forwards all non-overridden delegate methods to the original delegate.
public final class ClipboardRestrictedTextFieldDelegate: NSObject, UITextFieldDelegate {

    private let isContextMenuAllowed: Bool
    private weak var forwardingDelegate: (any UITextFieldDelegate)?

    /// Creates a standalone delegate with no forwarding.
    public init(isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    /// Creates a proxy delegate that intercepts clipboard actions
    /// and forwards everything else to the original delegate.
    public init(isContextMenuAllowed: Bool, forwardingTo delegate: any UITextFieldDelegate) {
        self.isContextMenuAllowed = isContextMenuAllowed
        self.forwardingDelegate = delegate
    }

    // MARK: - Edit Menu Restriction

    public func textField(
        _ textField: UITextField,
        editMenuForCharactersIn range: NSRange,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        if !isContextMenuAllowed {
            return UIMenu(children: [])
        }
        return forwardingDelegate?.textField?(
            textField,
            editMenuForCharactersIn: range,
            suggestedActions: suggestedActions
        )
    }

    // MARK: - Forwarding

    public override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return forwardingDelegate?.responds(to: aSelector) ?? false
    }

    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if forwardingDelegate?.responds(to: aSelector) == true {
            return forwardingDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }

    // MARK: - Convenience

    /// Applies clipboard restriction to a `UISearchBar`'s internal search text field.
    /// Returns the delegate instance which **must be stored with a strong reference**.
    /// Returns `nil` if clipboard is allowed (no restriction needed).
    public static func restrictSearchBarIfNeeded(
        _ searchBar: UISearchBar,
        isContextMenuAllowed: Bool
    ) -> ClipboardRestrictedTextFieldDelegate? {
        guard !isContextMenuAllowed else { return nil }
        let textField = searchBar.searchTextField
        let restricted: ClipboardRestrictedTextFieldDelegate
        if let original = textField.delegate {
            restricted = ClipboardRestrictedTextFieldDelegate(
                isContextMenuAllowed: false,
                forwardingTo: original
            )
        } else {
            restricted = ClipboardRestrictedTextFieldDelegate(isContextMenuAllowed: false)
        }
        textField.delegate = restricted
        return restricted
    }
}
