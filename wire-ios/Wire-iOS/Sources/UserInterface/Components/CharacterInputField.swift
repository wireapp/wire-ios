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

// MARK: - CharacterInputFieldDelegate

protocol CharacterInputFieldDelegate: AnyObject {
    func shouldAcceptChanges(_ inputField: CharacterInputField) -> Bool
    func didChangeText(_ inputField: CharacterInputField, to: String)
    func didFillInput(inputField: CharacterInputField, text: String)
}

// MARK: - TextContainer

protocol TextContainer: AnyObject {
    var text: String? { get set }
}

// MARK: - CharacterInputField

/// Custom input field implementation. Allows entering the characters from @c characterSet up to @c maxLength characters
/// Allows pasting the text.
final class CharacterInputField: UIControl, UITextInputTraits, TextContainer {
    // MARK: Lifecycle

    // MARK: - Overrides

    /// init method with custom settings
    ///
    /// - Parameters:
    ///   - maxLength: number of textfield will be created
    ///   - characterSet: characterSet accepted
    ///   - size: size of the view to be created (we take the width to calculate the size of each textField, the height
    /// for each textField's height)
    init(maxLength: Int, characterSet: CharacterSet, size: CGSize) {
        self.maxLength = maxLength
        self.characterSet = characterSet
        self.characterViews = (0 ..< maxLength).map { _ in CharacterView(parentSize: size) }

        super.init(frame: .zero)

        self.isAccessibilityElement = true
        self.shouldGroupAccessibilityChildren = true

        accessibilityHint = L10n.Localizable.Verification.codeHint

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: L10n.Localizable.General.paste,
                target: self,
                selector: #selector(UIResponderStandardEditActions.paste)
            ),
        ]

        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually

        characterViews.forEach(stackView.addArrangedSubview)

        addSubview(stackView)

        createConstraints()

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onLongPress(_:))
        )
        addGestureRecognizer(longPressGestureRecognizer)

        self.storage = String()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias ViewColors = SemanticColors.View

    final class CharacterView: UIView {
        // MARK: Lifecycle

        init(parentSize: CGSize) {
            self.parentSize = parentSize

            super.init(frame: .zero)

            layer.cornerRadius = 4
            layer.borderColor = ViewColors.borderCharacterInputField.cgColor
            backgroundColor = ViewColors.backgroundUserCell

            label.font = UIFont.systemFont(ofSize: 32)
            label.textColor = SemanticColors.Label.textDefault
            addSubview(label)

            createConstraints()
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        let parentSize: CGSize

        var character: Character? = .none {
            didSet {
                if let character {
                    label.text = String(character)
                    label.isHidden = false
                } else {
                    label.isHidden = true
                }
            }
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: parentSize.width > CGFloat.iPhone4Inch.width ? 50 : 44, height: parentSize.height)
        }

        // MARK: Private

        private let label = UILabel()

        private func createConstraints() {
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }
    }

    let maxLength: Int
    let characterSet: CharacterSet
    weak var delegate: CharacterInputFieldDelegate? = .none

    // MARK: - UITextInputTraits

    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType! = nil

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var canBecomeFocused: Bool {
        true
    }

    // MARK: - Public API

    var isFilled: Bool {
        storage.count >= maxLength
    }

    var text: String? {
        get {
            storage
        }

        set {
            storage = prepare(string: newValue ?? "")
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        updateCharacterViews(isFirstResponder: true)
        return result
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        updateCharacterViews(isFirstResponder: false)
        return result
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        becomeFirstResponder()
        layer.borderColor = ViewColors.borderCharacterInputFieldEnabled.cgColor
    }

    override func accessibilityActivate() -> Bool {
        becomeFirstResponder()
    }

    override func paste(_: Any?) {
        guard UIPasteboard.general.hasStrings, let valueToPaste = UIPasteboard.general.string else {
            return
        }

        notifyingDelegate {
            self.text = valueToPaste
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(paste(_:)):
            UIPasteboard.general.string != nil
        default:
            false
        }
    }

    // MARK: Fileprivate

    fileprivate var storage = String() {
        didSet {
            if storage.count > maxLength {
                storage = String(storage.prefix(maxLength))
            }

            updateCharacterViews(isFirstResponder: isFirstResponder)
            accessibilityValue = storage
        }
    }

    fileprivate func prepare(string: String) -> String {
        var result = string.filter { element -> Bool in
            guard element.unicodeScalars.count == 1, let firstScalar = element.unicodeScalars.first else {
                return false
            }
            return characterSet.contains(firstScalar)
        }

        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }

        return result
    }

    fileprivate func notifyingDelegate(_ action: () -> Void) {
        let wasFilled = isFilled
        let previousText = storage

        action()

        if previousText != storage {
            delegate?.didChangeText(self, to: storage)
        }

        if let text, !wasFilled, isFilled {
            delegate?.didFillInput(inputField: self, text: text)
        }
    }

    fileprivate func showMenu() {
        let menuController = UIMenuController.shared
        menuController.showMenu(from: self, rect: bounds)
    }

    // MARK: - Paste support

    @objc
    fileprivate func onLongPress(_: Any?) {
        showMenu()
    }

    // MARK: Private

    private let characterViews: [CharacterView]
    private let stackView = UIStackView()

    private func updateCharacterViews(isFirstResponder: Bool) {
        for index in 0 ... (maxLength - 1) {
            let characterView = characterViews[index]

            if let character = storage
                .count > index ? storage[storage.index(storage.startIndex, offsetBy: index)] : nil {
                characterView.character = character
            } else {
                characterView.character = .none
            }
        }
    }

    private func createConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}

// MARK: UIKeyInput

extension CharacterInputField: UIKeyInput {
    func insertText(_ text: String) {
        let shouldInsert = delegate?.shouldAcceptChanges(self) ?? true
        guard shouldInsert else { return }

        if text.rangeOfCharacter(from: CharacterSet.newlines) != nil {
            resignFirstResponder()
            return
        }

        let allowedChars = prepare(string: text)
        guard !allowedChars.isEmpty else {
            return
        }

        notifyingDelegate {
            self.storage.append(String(allowedChars))
        }

        layer.borderColor = ViewColors.borderCharacterInputFieldEnabled.cgColor
    }

    func deleteBackward() {
        guard !storage.isEmpty else {
            return
        }

        let shouldDelete = delegate?.shouldAcceptChanges(self) ?? true
        guard shouldDelete else { return }

        notifyingDelegate {
            self.storage.removeLast()
        }
    }

    var hasText: Bool {
        !storage.isEmpty
    }
}
