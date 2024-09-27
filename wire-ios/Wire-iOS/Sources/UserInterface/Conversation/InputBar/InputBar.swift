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

import Down
import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

extension Settings {
    var returnKeyType: UIReturnKeyType {
        let disableSendButton: Bool? = self[.sendButtonDisabled]
        return disableSendButton == true ? .send : .default
    }
}

// MARK: - EphemeralState

enum EphemeralState: Equatable {
    case conversation
    case message
    case none

    // MARK: Internal

    var isEphemeral: Bool {
        [.message, .conversation].contains(self)
    }
}

// MARK: - InputBarState

enum InputBarState: Equatable {
    case writing(ephemeral: EphemeralState)
    case editing(originalText: String, mentions: [Mention])
    case markingDown(ephemeral: EphemeralState)

    // MARK: Internal

    var isWriting: Bool {
        switch self {
        case .writing: true
        default: false
        }
    }

    var isEditing: Bool {
        switch self {
        case .editing: true
        default: false
        }
    }

    var isMarkingDown: Bool {
        switch self {
        case .markingDown: true
        default: false
        }
    }

    var isEphemeral: Bool {
        switch self {
        case let .markingDown(ephemeral):
            ephemeral.isEphemeral
        case let .writing(ephemeral):
            ephemeral.isEphemeral
        default:
            false
        }
    }

    var isEphemeralEnabled: Bool {
        switch self {
        case let .markingDown(ephemeral):
            ephemeral == .message
        case let .writing(ephemeral):
            ephemeral == .message
        default:
            false
        }
    }

    mutating func changeEphemeralState(to newState: EphemeralState) {
        switch self {
        case .markingDown:
            self = .markingDown(ephemeral: newState)
        case .writing:
            self = .writing(ephemeral: newState)
        default:
            return
        }
    }
}

// MARK: - InputBarConstants

private struct InputBarConstants {
    let buttonsBarHeight: CGFloat = 56
}

// MARK: - InputBar

final class InputBar: UIView {
    // MARK: Lifecycle

    required init(buttons: [UIButton]) {
        self.buttonsView = InputBarButtonsView(buttons: buttons)
        self.secondaryButtonsView = InputBarSecondaryButtonsView(
            editBarView: editingView,
            markdownBarView: markdownView
        )

        super.init(frame: CGRect.zero)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        addGestureRecognizer(tapGestureRecognizer)
        buttonsView.clipsToBounds = true
        buttonContainer.clipsToBounds = true

        [leftAccessoryView, textView, rightAccessoryStackView, buttonContainer, buttonRowSeparator].forEach(addSubview)
        buttonContainer.addSubview(buttonInnerContainer)
        [buttonsView, secondaryButtonsView].forEach(buttonInnerContainer.addSubview)

        setupViews()
        updateRightAccessoryStackViewLayoutMargins()
        createConstraints()

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            markdownView,
            selector: #selector(markdownView.textViewDidChangeActiveMarkdown),
            name: Notification.Name.MarkdownTextViewDidChangeActiveMarkdown,
            object: textView
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(textViewTextDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(textViewDidBeginEditing),
            name: UITextView.textDidBeginEditingNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(textViewDidEndEditing),
            name: UITextView.textDidEndEditingNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(sendButtonEnablingDidApplyChanges),
            name: NSNotification.Name.disableSendButtonChanged,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias ConversationInputBar = L10n.Localizable.Conversation.InputBar

    static let rightIconSize: CGFloat = 32

    let textView = MarkdownTextView(with: DownStyle.compact)
    let leftAccessoryView = UIView()
    let rightAccessoryStackView: UIStackView = {
        let stackView = UIStackView()

        let rightInset = (stackView.conversationHorizontalMargins.left - rightIconSize) / 2

        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    // Contains and clips the buttonInnerContainer
    let buttonContainer = UIView()

    // Contains editingView and mardownView
    let secondaryButtonsView: InputBarSecondaryButtonsView

    let buttonsView: InputBarButtonsView
    let editingView = InputBarEditView()

    let markdownView = MarkdownBarView()

    var barBackgroundColor: UIColor? = SemanticColors.SearchBar.backgroundInputView
    var writingSeparatorColor: UIColor? = SemanticColors.View.backgroundSeparatorCell
    var editingSeparatorColor: UIColor? = SemanticColors.View.backgroundSeparatorEditView

    var placeholderColor: UIColor = SemanticColors.SearchBar.textInputViewPlaceholder
    var textColor: UIColor? = SemanticColors.SearchBar.textInputView

    var editingBackgroundColor: UIColor {
        .lowAccentColor()
    }

    var ephemeralColor: UIColor {
        .accent()
    }

    var isEditing: Bool {
        inputBarState.isEditing
    }

    var isMarkingDown: Bool {
        inputBarState.isMarkingDown
    }

    var invisibleInputAccessoryView: InvisibleInputAccessoryView? {
        didSet {
            textView.inputAccessoryView = invisibleInputAccessoryView
        }
    }

    override var bounds: CGRect {
        didSet {
            invisibleInputAccessoryView?.overriddenIntrinsicContentSize = CGSize(
                width: UIView.noIntrinsicMetric,
                height: bounds.height
            )
        }
    }

    func changeEphemeralState(to newState: EphemeralState) {
        inputBarState.changeEphemeralState(to: newState)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // This is a workaround for UITextView truncating long contents.
        // However, this breaks the text view on iOS 8 ¯\_(ツ)_/¯.
        textView.isScrollEnabled = false
        textView.isScrollEnabled = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }

        updateLeftAccessoryViewWidth()
        updateRightAccessoryStackViewLayoutMargins()
    }

    func updateReturnKey() {
        textView.returnKeyType = isMarkingDown ? .default : Settings.shared.returnKeyType
        textView.reloadInputViews()
    }

    func updatePlaceholder() {
        textView.attributedPlaceholder = placeholderText(for: inputBarState)
        textView.setNeedsLayout()
    }

    func placeholderText(for state: InputBarState) -> NSAttributedString? {
        var placeholder = NSAttributedString(string: ConversationInputBar.placeholder)

        if inputBarState.isEphemeral {
            placeholder = NSAttributedString(string: ConversationInputBar.placeholderEphemeral) && ephemeralColor
        }
        if state.isEditing {
            return nil
        } else {
            return placeholder
        }
    }

    // MARK: - Disable interactions on the lower part to not to interfere with the keyboard

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if textView.isFirstResponder {
            if super.point(inside: point, with: event) {
                let locationInButtonRow = buttonInnerContainer.convert(point, from: self)
                return locationInButtonRow.y < buttonInnerContainer.bounds.height / 1.3
            } else {
                return false
            }
        } else {
            return super.point(inside: point, with: event)
        }
    }

    // MARK: - InputBarState

    func setInputBarState(_ state: InputBarState, animated: Bool) {
        let oldState = inputBarState
        inputBarState = state
        updateInputBar(withState: state, oldState: oldState, animated: animated)
    }

    func updateEphemeralState() {
        guard inputBarState.isWriting else { return }
        updateColors()
        updatePlaceholder()
    }

    func updateColors() {
        backgroundColor = backgroundColor(forInputBarState: inputBarState)
        buttonRowSeparator.backgroundColor = isEditing ? editingSeparatorColor : writingSeparatorColor

        updatePlaceholderColors()

        textView.tintColor = .accent()
        textView.updateTextColor(base: isEditing ? SemanticColors.Label.textDefault : textColor)

        var buttons = buttonsView.buttons

        buttons.append(buttonsView.expandRowButton)

        buttons.forEach { button in
            guard let button = button as? IconButton else { return }

            button.layer.borderWidth = 1

            button.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
            button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemEnabled, for: .normal)
            button.setBorderColor(SemanticColors.Button.borderInputBarItemEnabled, for: .normal)

            button.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .highlighted)
            button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .highlighted)
            button.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .highlighted)

            button.setIconColor(SemanticColors.Button.textInputBarItemHighlighted, for: .selected)
            button.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemHighlighted, for: .selected)
            button.setBorderColor(SemanticColors.Button.borderInputBarItemHighlighted, for: .selected)
        }
    }

    // MARK: – Editing View State

    func setInputBarText(_ text: String, mentions: [Mention]) {
        textView.setText(text, withMentions: mentions)
        textView.setContentOffset(.zero, animated: false)
        textView.undoManager?.removeAllActions()
        updateEditViewState()
    }

    func undo() {
        guard inputBarState.isEditing else { return }
        guard let undoManager = textView.undoManager, undoManager.canUndo else { return }
        undoManager.undo()
        updateEditViewState()
    }

    // MARK: Fileprivate

    fileprivate let buttonRowSeparator = UIView()
    fileprivate let constants = InputBarConstants()

    fileprivate func setupViews() {
        textView.accessibilityIdentifier = "inputField"

        updatePlaceholder()
        textView.lineFragmentPadding = 0
        textView.textAlignment = .natural
        textView.textContainerInset = UIEdgeInsets(
            top: inputBarVerticalInset / 2,
            left: 0,
            bottom: inputBarVerticalInset / 2,
            right: 4
        )
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 21, left: 10, bottom: 21, right: 0)
        textView.keyboardType = .default
        textView.keyboardAppearance = .default
        textView.tintAdjustmentMode = .automatic
        textView.font = textViewFont
        textView.placeholderFont = textViewFont
        textView.backgroundColor = .clear

        markdownView.delegate = textView
        addBorder(for: .top)
        updateReturnKey()

        updateInputBar(withState: inputBarState, animated: false)
        updateColors()
    }

    fileprivate func createConstraints() {
        [
            buttonContainer,
            textView,
            buttonRowSeparator,
            leftAccessoryView,
            rightAccessoryStackView,
            secondaryButtonsView,
            buttonsView,
            buttonInnerContainer,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let rightAccessoryViewWidthConstraint = rightAccessoryStackView.widthAnchor.constraint(equalToConstant: 0)
        rightAccessoryViewWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            leftAccessoryView.leadingAnchor.constraint(equalTo: leftAccessoryView.superview!.leadingAnchor),
            leftAccessoryView.topAnchor.constraint(equalTo: leftAccessoryView.superview!.topAnchor),
            leftAccessoryView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),
            leftAccessoryViewWidthConstraint,

            rightAccessoryStackView.trailingAnchor
                .constraint(equalTo: rightAccessoryStackView.superview!.trailingAnchor),
            rightAccessoryStackView.topAnchor.constraint(equalTo: rightAccessoryStackView.superview!.topAnchor),
            rightAccessoryViewWidthConstraint,
            rightAccessoryStackView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),

            buttonContainer.topAnchor.constraint(equalTo: textView.bottomAnchor),
            textView.topAnchor.constraint(equalTo: textView.superview!.topAnchor),
            textView.leadingAnchor.constraint(equalTo: leftAccessoryView.trailingAnchor),
            textView.trailingAnchor.constraint(lessThanOrEqualTo: textView.superview!.trailingAnchor, constant: -16),
            textView.trailingAnchor.constraint(equalTo: rightAccessoryStackView.leadingAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),

            buttonRowSeparator.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            buttonRowSeparator.leadingAnchor.constraint(
                equalTo: buttonRowSeparator.superview!.leadingAnchor,
                constant: 16
            ),
            buttonRowSeparator.trailingAnchor.constraint(
                equalTo: buttonRowSeparator.superview!.trailingAnchor,
                constant: -16
            ),
            buttonRowSeparator.heightAnchor.constraint(equalToConstant: .hairline),

            secondaryButtonsView.topAnchor.constraint(equalTo: buttonInnerContainer.topAnchor),
            secondaryButtonsView.leadingAnchor.constraint(equalTo: buttonInnerContainer.leadingAnchor),
            secondaryButtonsView.trailingAnchor.constraint(equalTo: buttonInnerContainer.trailingAnchor),
            secondaryButtonsView.bottomAnchor.constraint(equalTo: buttonsView.topAnchor),
            secondaryButtonsView.heightAnchor.constraint(equalToConstant: constants.buttonsBarHeight),

            buttonsView.leadingAnchor.constraint(equalTo: buttonInnerContainer.leadingAnchor),
            buttonsView.trailingAnchor.constraint(lessThanOrEqualTo: buttonInnerContainer.trailingAnchor),
            buttonsView.bottomAnchor.constraint(equalTo: buttonInnerContainer.bottomAnchor),

            buttonContainer.bottomAnchor.constraint(equalTo: buttonContainer.superview!.bottomAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: buttonContainer.superview!.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: buttonContainer.superview!.trailingAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: constants.buttonsBarHeight),

            buttonInnerContainer.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            buttonInnerContainer.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            rowTopInsetConstraint,
        ])
    }

    fileprivate func updateLeftAccessoryViewWidth() {
        leftAccessoryViewWidthConstraint.constant = conversationHorizontalMargins.left
    }

    fileprivate func updateRightAccessoryStackViewLayoutMargins() {
        let rightInset = (conversationHorizontalMargins.left - InputBar.rightIconSize) / 2
        rightAccessoryStackView.layoutMargins = UIEdgeInsets(top: 0, left: rightInset, bottom: 0, right: rightInset)
    }

    fileprivate func backgroundColor(forInputBarState state: InputBarState) -> UIColor? {
        guard let writingColor = barBackgroundColor else { return nil }
        return state.isWriting || state.isMarkingDown ? writingColor : editingBackgroundColor
    }

    fileprivate func updatePlaceholderColors() {
        if inputBarState.isEphemeral, inputBarState.isEphemeralEnabled {
            textView.placeholderTextColor = ephemeralColor
        } else {
            textView.placeholderTextColor = placeholderColor
        }
    }

    fileprivate func updateEditViewState() {
        if case let .editing(text, _) = inputBarState {
            let canUndo = textView.undoManager?.canUndo ?? false
            editingView.undoButton.isEnabled = canUndo

            // We do not want to enable the confirm button when
            // the text is the same as the original message
            let trimmedText = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let hasChanges = text != trimmedText && canUndo
            editingView.confirmButton.isEnabled = hasChanges
        }
    }

    // MARK: Private

    private let inputBarVerticalInset: CGFloat = 34
    private let textViewFont = FontSpec.normalRegularFont.font!

    private lazy var rowTopInsetConstraint: NSLayoutConstraint = buttonInnerContainer.topAnchor.constraint(
        equalTo: buttonContainer.topAnchor,
        constant: -constants.buttonsBarHeight
    )

    // Contains the secondaryButtonsView and buttonsView
    private let buttonInnerContainer = UIView()

    private lazy var leftAccessoryViewWidthConstraint: NSLayoutConstraint = leftAccessoryView.widthAnchor
        .constraint(equalToConstant: conversationHorizontalMargins.left)

    private var inputBarState: InputBarState = .writing(ephemeral: .none) {
        didSet {
            updatePlaceholder()
            updatePlaceholderColors()
        }
    }

    /// Update return key type when receiving a notification (from setting->toggle send key option)
    @objc
    private func sendButtonEnablingDidApplyChanges() {
        updateReturnKey()
    }

    @objc
    private func didTapBackground(_ gestureRecognizer: UITapGestureRecognizer!) {
        guard gestureRecognizer.state == .recognized else { return }
        buttonsView.showRow(0, animated: true)
    }

    private func updateInputBar(withState state: InputBarState, oldState: InputBarState? = nil, animated: Bool = true) {
        updateEditViewState()
        updatePlaceholder()
        updateReturnKey()
        rowTopInsetConstraint.constant = state.isWriting ? -constants.buttonsBarHeight : 0

        let textViewChanges = {
            switch state {
            case .writing:
                if let oldState, oldState.isEditing {
                    self.textView.text = nil
                }

            case let .editing(text, mentions):
                self.setInputBarText(text, mentions: mentions)
                self.secondaryButtonsView.setEditBarView()

            case .markingDown:
                self.secondaryButtonsView.setMarkdownBarView()
            }
        }

        let completion: () -> Void = {
            self.updateColors()
            self.updatePlaceholderColors()

            if state.isEditing {
                self.textView.becomeFirstResponder()
            }
        }

        if animated, superview != nil {
            UIView.animate(easing: .easeInOutExpo, duration: 0.3, animations: layoutIfNeeded)
            UIView.transition(with: textView, duration: 0.1, options: [], animations: textViewChanges) { _ in
                self.updateColors()
                completion()
            }
        } else {
            layoutIfNeeded()
            textViewChanges()
            completion()
        }
    }
}

extension InputBar {
    @objc
    func textViewTextDidChange(_: Notification) {
        updateEditViewState()
    }

    @objc
    func textViewDidBeginEditing(_: Notification) {
        updateEditViewState()
    }

    @objc
    func textViewDidEndEditing(_: Notification) {
        updateEditViewState()
    }
}
