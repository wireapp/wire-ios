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

import SwiftUI
import UIKit

// TODO: [WPB-19321] Enforce to use it and remove isContextMenuAllowed from the parameters
/// A UITextField subclass that provides centralized control over context menu actions
/// such as copy, paste, select, select all, and the AutoFill menu.
///
/// Use `isContextMenuAllowed` to enable or restrict specific actions.
/// This base class is designed to be subclassed by custom UITextField implementations
/// that require consistent context menu behavior across the app.
open class ContextMenuControllableUITextField: UITextField {

    private let isContextMenuAllowed: Bool

    public init(frame: CGRect, isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed

        super.init(frame: frame)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func canPerformAction(
        _ action: Selector,
        withSender sender: Any?
    ) -> Bool {
        if !isContextMenuAllowed {
            let validActions: [Selector] = [
                #selector((any UIResponderStandardEditActions).select(_:)),
                #selector((any UIResponderStandardEditActions).selectAll(_:))
            ]
            return !(text?.isEmpty ?? true) && validActions.contains(action)
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    public override func buildMenu(with builder: any UIMenuBuilder) {
        if !isContextMenuAllowed {
            if #available(iOS 17.0, *) {
                builder.remove(menu: .autoFill)
            }
        }
    }

}

public struct ContextMenuControllableTextField: UIViewRepresentable {
    @Binding var text: String
    private let placeholder: String
    private let isSecureTextEntry: Bool
    private let placeholderColor: Color?
    private let isContextMenuAllowed: Bool

    public init(
        text: Binding<String>,
        placeholder: String,
        isSecureTextEntry: Bool = false,
        placeholderColor: Color? = nil,
        isContextMenuAllowed: Bool
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isSecureTextEntry = isSecureTextEntry
        self.placeholderColor = placeholderColor
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField: UITextField = ContextMenuControllableUITextField(
            frame: .zero,
            isContextMenuAllowed: isContextMenuAllowed
        )
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.text = text
        textField.autocorrectionType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        if isSecureTextEntry {
            textField.isSecureTextEntry = true
            textField.textContentType = .oneTimeCode
        }
        if let placeholderColor {
            let font = UIFont.preferredFont(forTextStyle: .body)
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(placeholderColor),
                .font: font
            ]
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: placeholderAttributes
            )
        }

        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ContextMenuControllableTextField

        init(_ parent: ContextMenuControllableTextField) {
            self.parent = parent
        }

        public func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
