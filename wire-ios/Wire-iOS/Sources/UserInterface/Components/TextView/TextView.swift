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
import WireSystem

private let zmLog = ZMSLog(tag: "TextView")

// MARK: - InformalTextViewDelegate

protocol InformalTextViewDelegate: AnyObject {
    func textView(_ textView: UITextView, hasImageToPaste image: MediaAsset)
    func textView(_ textView: UITextView, firstResponderChanged resigned: Bool)
}

// MARK: - TextView

// Inspired by https://github.com/samsoffes/sstoolkit/blob/master/SSToolkit/SSTextView.m
// and by http://derpturkey.com/placeholder-in-uitextview/
class TextView: UITextView {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }

    // MARK: Internal

    weak var informalTextViewDelegate: InformalTextViewDelegate?

    var language: String?

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            placeholderLabel.sizeToFit()
            showOrHidePlaceholder()
        }
    }

    var attributedPlaceholder: NSAttributedString? {
        didSet {
            let mutableCopy = if let attributedPlaceholder {
                NSMutableAttributedString(attributedString: attributedPlaceholder)
            } else {
                NSMutableAttributedString()
            }
            mutableCopy.addAttribute(
                .foregroundColor,
                value: placeholderTextColor,
                range: NSRange(location: 0, length: mutableCopy.length)
            )
            placeholderLabel.attributedText = mutableCopy
            placeholderLabel.sizeToFit()
            showOrHidePlaceholder()
        }
    }

    var placeholderTextColor: UIColor = .lightGray {
        didSet {
            placeholderLabel.textColor = placeholderTextColor
        }
    }

    var placeholderFont: UIFont? {
        didSet {
            placeholderLabel.font = placeholderFont
        }
    }

    var lineFragmentPadding: CGFloat = 0 {
        didSet {
            textContainer.lineFragmentPadding = lineFragmentPadding
        }
    }

    var placeholderTextAlignment = NSTextAlignment.natural {
        didSet {
            placeholderLabel.textAlignment = placeholderTextAlignment
        }
    }

    override var accessibilityValue: String? {
        get {
            text.isEmpty ? placeholderLabel.accessibilityValue : super.accessibilityValue
        }

        set {
            super.accessibilityValue = newValue
        }
    }

    override var text: String! {
        didSet {
            showOrHidePlaceholder()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            showOrHidePlaceholder()
        }
    }

    // MARK: Language

    override var textInputMode: UITextInputMode? {
        overriddenTextInputMode
    }

    /// custom inset for placeholder, only left and right inset value is applied (The placeholder is align center
    /// vertically)
    var placeholderTextContainerInset: UIEdgeInsets = .zero {
        didSet {
            placeholderLabelLeftConstraint?.constant = placeholderTextContainerInset.left
            placeholderLabelRightConstraint?.constant = placeholderTextContainerInset.right
        }
    }

    @objc
    func textChanged(_: Notification?) {
        showOrHidePlaceholder()
    }

    @objc
    func showOrHidePlaceholder() {
        placeholderLabel.alpha = text.isEmpty ? 1 : 0
    }

    // MARK: - Copy/Pasting

    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        zmLog.debug("types available: \(pasteboard.types)")

        if pasteboard.hasImages,
           let image = UIPasteboard.general.mediaAsset() {
            informalTextViewDelegate?.textView(self, hasImageToPaste: image)
        } else if pasteboard.hasStrings {
            super.paste(sender)
        } else if pasteboard.hasURLs {
            if pasteboard.string?.isEmpty == false {
                super.paste(sender)
            } else if pasteboard.url != nil {
                super.paste(sender)
            }
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            let pasteboard = UIPasteboard.general
            return pasteboard.hasImages || pasteboard.hasStrings
        }

        return super.canPerformAction(action, withSender: sender)
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()

        informalTextViewDelegate?.textView(self, firstResponderChanged: resigned)

        return resigned
    }

    // MARK: Private

    private let placeholderLabel = TransformLabel()
    private var placeholderLabelLeftConstraint: NSLayoutConstraint?
    private var placeholderLabelRightConstraint: NSLayoutConstraint?

    // MARK: Setup

    private func setup() {
        placeholderTextContainerInset = textContainerInset

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textChanged(_:)),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        setupPlaceholderLabel()

        if AutomationHelper.sharedHelper.disableAutocorrection {
            autocorrectionType = .no
        }
    }

    private func setupPlaceholderLabel() {
        let linePadding = textContainer.lineFragmentPadding
        placeholderLabel.font = placeholderFont
        placeholderLabel.textColor = placeholderTextColor
        placeholderLabel.textAlignment = placeholderTextAlignment
        placeholderLabel.isAccessibilityElement = false

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(placeholderLabel)

        placeholderLabelLeftConstraint = placeholderLabel.leftAnchor.constraint(
            equalTo: leftAnchor,
            constant: placeholderTextContainerInset.left + linePadding
        )
        placeholderLabelRightConstraint = placeholderLabel.rightAnchor.constraint(
            equalTo: rightAnchor,
            constant: placeholderTextContainerInset.right - linePadding
        )

        NSLayoutConstraint.activate([
            placeholderLabelLeftConstraint!,
            placeholderLabelRightConstraint!,
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
