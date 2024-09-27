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
import WireDesign
import WireReusableUIComponents
import WireSystem

// MARK: - TextSearchInputViewDelegate

protocol TextSearchInputViewDelegate: AnyObject {
    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo: String)
    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool
}

// MARK: - TextSearchInputView

final class TextSearchInputView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = SemanticColors.View.backgroundDefault

        iconView.setTemplateIcon(.search, size: .tiny)
        iconView.tintColor = SearchBarColors.backgroundButton
        iconView.contentMode = .center
        searchInput.delegate = self
        searchInput.autocorrectionType = .no
        searchInput.accessibilityLabel = "Search"
        searchInput.accessibilityIdentifier = "search input"
        searchInput.keyboardAppearance = .default
        searchInput.textContainerInset = UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 8)
        searchInput.font = FontSpec.body.font!
        placeholderLabel.textAlignment = .natural
        placeholderLabel.isAccessibilityElement = false

        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(
            self,
            action: #selector(TextSearchInputView.onCancelButtonTouchUpInside(_:)),
            for: .touchUpInside
        )
        clearButton.isHidden = true
        clearButton.accessibilityIdentifier = "cancel search"
        clearButton.accessibilityLabel = L10n.Accessibility.SearchView.ClearButton.description

        clearButton.setIconColor(SearchBarColors.backgroundButton, for: .normal)

        spinner.color = SemanticColors.Icon.foregroundDefault
        spinner.iconSize = StyleKitIcon.Size.tiny.rawValue
        [searchInput, iconView, clearButton, placeholderLabel, spinner].forEach(addSubview)

        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    typealias SearchBarColors = SemanticColors.SearchBar

    let iconView = UIImageView()
    let searchInput = SearchTextView(style: .default)
    let placeholderLabel = DynamicFontLabel(
        fontSpec: .body,
        color: SearchBarColors.textInputViewPlaceholder
    )
    let clearButton = IconButton(style: .default)

    weak var delegate: TextSearchInputViewDelegate?

    var query = "" {
        didSet {
            updateForSearchQuery()
            delegate?.searchView(self, didChangeQueryTo: query)
        }
    }

    var placeholderString = "" {
        didSet {
            placeholderLabel.text = placeholderString
        }
    }

    var isLoading = false {
        didSet {
            spinner.isAnimating = isLoading
        }
    }

    @objc
    func onCancelButtonTouchUpInside(_: AnyObject!) {
        query = ""
        searchInput.text = ""
        searchInput.resignFirstResponder()
    }

    // MARK: Fileprivate

    fileprivate func updatePlaceholderLabel() {
        placeholderLabel.isHidden = !query.isEmpty
    }

    fileprivate func updateForSearchQuery() {
        updatePlaceholderLabel()
        clearButton.isHidden = query.isEmpty
    }

    // MARK: Private

    private let spinner = ProgressSpinner()

    private func createConstraints() {
        for item in [self, iconView, searchInput, placeholderLabel, clearButton, spinner] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate(
            searchInput.fitInConstraints(view: self, inset: 8) + [
                iconView.leadingAnchor.constraint(equalTo: searchInput.leadingAnchor, constant: 16),
                iconView.centerYAnchor.constraint(equalTo: searchInput.centerYAnchor),

                iconView.topAnchor.constraint(equalTo: topAnchor),
                iconView.bottomAnchor.constraint(equalTo: bottomAnchor),

                heightAnchor.constraint(lessThanOrEqualToConstant: 100),

                placeholderLabel.leadingAnchor.constraint(equalTo: searchInput.leadingAnchor, constant: 48),
                placeholderLabel.topAnchor.constraint(equalTo: searchInput.topAnchor),
                placeholderLabel.bottomAnchor.constraint(equalTo: searchInput.bottomAnchor),
                placeholderLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor),

                clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                clearButton.trailingAnchor.constraint(equalTo: searchInput.trailingAnchor, constant: -16),
                clearButton.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),
                clearButton.heightAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),

                spinner.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6),
                spinner.centerYAnchor.constraint(equalTo: clearButton.centerYAnchor),
                spinner.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue),
            ]
        )
    }
}

// MARK: UITextViewDelegate

extension TextSearchInputView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let currentText = textView.text else {
            return true
        }
        let containsReturn = text.rangeOfCharacter(from: .newlines, options: [], range: .none) != .none

        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
        query = containsReturn ? currentText : newText

        if containsReturn {
            let shouldReturn = delegate?.searchViewShouldReturn(self) ?? true
            if shouldReturn {
                textView.resignFirstResponder()
            }
        }

        return !containsReturn
    }

    func textViewDidBeginEditing(_: UITextView) {
        updatePlaceholderLabel()
    }

    func textViewDidEndEditing(_: UITextView) {
        updatePlaceholderLabel()
    }
}
