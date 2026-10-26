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
    var customPlaceholderColor: UIColor?

    public init(frame: CGRect, isContextMenuAllowed: Bool) {
        self.isContextMenuAllowed = isContextMenuAllowed

        super.init(frame: frame)
    }

    open override func drawPlaceholder(in rect: CGRect) {
        if attributedPlaceholder != nil {
            super.drawPlaceholder(in: rect)
            return
        }

        guard let placeholder else { return }
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        let color = customPlaceholderColor ?? .placeholderText
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let textHeight = min(font.lineHeight, rect.height)
        let yOffset = max(0, (rect.height - textHeight) / 2)
        placeholder.draw(
            in: CGRect(x: rect.minX, y: rect.minY + yOffset, width: rect.width, height: textHeight),
            withAttributes: attributes
        )
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
            builder.remove(menu: .autoFill)
        }
    }

}

public struct ContextMenuControllableTextField: UIViewRepresentable {
    @Binding var text: String
    private let placeholder: String
    private let isSecureTextEntry: Bool
    private let placeholderColor: Color?
    private let isContextMenuAllowed: Bool
    private let textAlignment: NSTextAlignment
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let autocapitalizationType: UITextAutocapitalizationType
    private let textColor: UIColor?

    public init(
        text: Binding<String>,
        placeholder: String,
        isSecureTextEntry: Bool = false,
        placeholderColor: Color? = nil,
        isContextMenuAllowed: Bool,
        textAlignment: NSTextAlignment = .natural,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalizationType: UITextAutocapitalizationType = .none,
        textColor: UIColor? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isSecureTextEntry = isSecureTextEntry
        self.placeholderColor = placeholderColor
        self.isContextMenuAllowed = isContextMenuAllowed
        self.textAlignment = textAlignment
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalizationType = autocapitalizationType
        self.textColor = textColor
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = ContextMenuControllableUITextField(
            frame: .zero,
            isContextMenuAllowed: isContextMenuAllowed
        )
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.text = text
        textField.autocorrectionType = .no
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textAlignment = textAlignment
        textField.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        textField.customPlaceholderColor = placeholderColor.map(UIColor.init)
        if isSecureTextEntry {
            textField.isSecureTextEntry = true
        }

        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        // Only assign when the value actually changed: setting `text` makes UIKit fire
        // `textFieldDidChangeSelection`, whose write-back to the binding would publish
        // a change from within this view update (undefined behavior in SwiftUI).
        if uiView.text != text {
            uiView.text = text
        }
        uiView.keyboardType = keyboardType
        uiView.textContentType = textContentType
        uiView.autocapitalizationType = autocapitalizationType
        uiView.textColor = textColor ?? .label
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
            // Skip redundant writes: this delegate call also fires for selection-only
            // changes and as a side effect of `updateUIView` setting the text, in which
            // case publishing to the binding would happen during a SwiftUI view update.
            let newText = textField.text ?? ""
            guard parent.text != newText else { return }
            parent.text = newText
        }
    }
}
