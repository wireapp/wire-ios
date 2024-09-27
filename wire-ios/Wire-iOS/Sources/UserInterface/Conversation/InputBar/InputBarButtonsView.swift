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

// MARK: - InputBarRowConstants

private enum InputBarRowConstants {
    static let titleTopMargin: CGFloat = 10
    static let minimumButtonWidthIPhone5: CGFloat = 53
    static let minimumButtonWidth: CGFloat = 56
    static let buttonsBarHeight: CGFloat = 56
    static let iconSize = StyleKitIcon.Size.tiny.rawValue

    static func minimumButtonWidth(forWidth width: CGFloat) -> CGFloat {
        width <= CGFloat.iPhone4Inch.width ? InputBarRowConstants.minimumButtonWidthIPhone5 : InputBarRowConstants
            .minimumButtonWidth
    }
}

// MARK: - InputBarButtonsView

/// `InputBarButtonsView` is a UIView responsible for managing and displaying a row of buttons within an `InputBar`.
/// It handles the dynamic layout of buttons, adjusting to various screen sizes and orientations, and responds
/// to state changes from its parent view. This class encapsulates all button-related interactions and ensures
/// accessibility compliance, making the button row navigable and usable by all users. It also contributes to the
/// overall layout of the `InputBar` by defining constraints relative to the `InputBarConstants`.
///
/// The view listens to changes in button configurations and updates its layout and accessibility features
/// accordingly. It also manages button interactions and communicates actions up to the `InputBar`, which can
/// alter the state of the input bar, such as switching between editing and composing states.
///
/// Usage:
/// Initialize `InputBarButtonsView` with an array of `UIButton` objects that represent the actions available
/// in the `InputBar`. The view automatically configures constraints and layout based on the provided buttons.
/// It is a subcomponent of `InputBar` and should be used in conjunction with it.
///
/// Example Initialization:
/// ```
/// let buttons: [UIButton] = [sendButton, attachButton, emojiButton]
/// let buttonsView = InputBarButtonsView(buttons: buttons)
/// // Add `buttonsView` to an `InputBar` instance
/// ```
///
/// - Note: This class is intended for use as part of the `InputBar` and relies on the `InputBarConstants`
///         for consistent styling and layout metrics.
final class InputBarButtonsView: UIView {
    // MARK: Lifecycle

    required init(buttons: [UIButton]) {
        self.buttons = buttons
        super.init(frame: CGRect.zero)
        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias RowIndex = UInt

    private(set) var multilineLayout = false
    private(set) var currentRow: RowIndex = 0

    let expandRowButton = IconButton()

    var buttons: [UIButton] {
        didSet {
            layoutAndConstrainButtonRows()
        }
    }

    func configureViews() {
        addSubview(buttonInnerContainer)

        for button in buttons {
            let action = UIAction { [weak self] _ in
                self?.anyButtonPressed()
            }

            button.addAction(action, for: .touchUpInside)
            buttonInnerContainer.addSubview(button)
        }

        buttonInnerContainer.clipsToBounds = true
        expandRowButton.accessibilityIdentifier = "showOtherRowButton"
        expandRowButton.accessibilityLabel = L10n.Accessibility.Conversation.MoreButton.description
        expandRowButton.hitAreaPadding = .zero
        expandRowButton.setIcon(.ellipsis, size: .tiny, for: [])

        let action = UIAction { [weak self] _ in
            self?.ellipsisButtonPressed()
        }

        expandRowButton.addAction(action, for: .touchUpInside)

        buttonOuterContainer.addSubview(buttonInnerContainer)
        buttonOuterContainer.clipsToBounds = true
        addSubview(buttonOuterContainer)
        addSubview(expandRowButton)
        backgroundColor = SemanticColors.SearchBar.backgroundInputView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size.width != lastLayoutWidth else { return }
        layoutAndConstrainButtonRows()
        lastLayoutWidth = bounds.size.width
    }

    func showRow(_ rowIndex: RowIndex, animated: Bool) {
        let animationDuration = 0.35
        guard rowIndex != currentRow else { return }
        currentRow = rowIndex
        buttonRowTopInset.constant = CGFloat(rowIndex) * InputBarRowConstants.buttonsBarHeight
        UIView.animate(easing: .easeInOutExpo, duration: animated ? animationDuration : 0, animations: layoutIfNeeded)
        setupAccessibility()
    }

    // MARK: Private

    private enum ButtonPosition {
        case first
        case middle
        case last
    }

    private lazy var buttonRowTopInset: NSLayoutConstraint = buttonOuterContainer.topAnchor
        .constraint(equalTo: buttonInnerContainer.topAnchor)
    private lazy var buttonRowHeight: NSLayoutConstraint = buttonInnerContainer.heightAnchor
        .constraint(equalToConstant: 0)
    private var lastLayoutWidth: CGFloat = 0

    private let buttonInnerContainer = UIView()
    private let buttonOuterContainer = UIView()

    private var customButtonCount: Int {
        let minButtonWidth: CGFloat = InputBarRowConstants.minimumButtonWidth(forWidth: bounds.width)
        let ratio = floorf(Float(bounds.width / minButtonWidth))
        let numberOfButtons = Int(ratio)
        return numberOfButtons >= 1 ? numberOfButtons - 1 : 0
    }

    // MARK: - Button Layout

    private var buttonMargin: CGFloat {
        conversationHorizontalMargins.left / 2 - StyleKitIcon.Size.tiny.rawValue / 2
    }

    private func createConstraints() {
        let widthConstraint = widthAnchor.constraint(equalToConstant: 600)
        widthConstraint.priority = UILayoutPriority(rawValue: 750)

        for item in [buttonInnerContainer, buttonOuterContainer] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            buttonRowTopInset,
            buttonInnerContainer.leadingAnchor.constraint(equalTo: buttonOuterContainer.leadingAnchor),
            buttonInnerContainer.trailingAnchor.constraint(equalTo: buttonOuterContainer.trailingAnchor),
            buttonInnerContainer.bottomAnchor.constraint(equalTo: buttonOuterContainer.bottomAnchor),
            buttonRowHeight,

            buttonOuterContainer.heightAnchor.constraint(equalToConstant: InputBarRowConstants.buttonsBarHeight),
            buttonOuterContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIScreen.safeArea.bottom),
            buttonOuterContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonOuterContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonOuterContainer.topAnchor.constraint(equalTo: topAnchor),

            heightAnchor.constraint(equalTo: buttonOuterContainer.heightAnchor, constant: UIScreen.safeArea.bottom),
            widthConstraint,
        ])
    }

    private func setupAccessibility() {
        if multilineLayout {
            let firstRowButtons = [UIButton](buttons.prefix(customButtonCount))
            let secondRowButtons = [UIButton](buttons.suffix(buttons.count - customButtonCount))

            for button in buttons {
                button.isAccessibilityElement = currentRow == 0
                    ? firstRowButtons.contains(button)
                    : secondRowButtons.contains(button)
            }
        }
    }

    private func layoutAndConstrainButtonRows() {
        let minButtonWidth = InputBarRowConstants.minimumButtonWidth(forWidth: bounds.width)
        let maxNumberOfButtonsPerRow = Int(floorf(Float(bounds.width / minButtonWidth)))

        guard bounds.size.width >= minButtonWidth * 2 else {
            return
        }

        setupButtonContainer()

        let (firstRow, secondRow, isMultilineLayout) = determineButtonLayout()
        buttonRowHeight.constant = isMultilineLayout ? InputBarRowConstants.buttonsBarHeight * 2 : InputBarRowConstants
            .buttonsBarHeight
        expandRowButton.isHidden = !isMultilineLayout

        roundButtons(firstRow: firstRow, secondRow: secondRow)

        var constraints = constrainRowOfButtons(
            firstRow,
            inset: 0,
            rowIsFull: true,
            referenceButton: .none
        )

        defer {
            NSLayoutConstraint.activate(constraints)
            showRow(0, animated: true)
        }

        guard !secondRow.isEmpty else {
            return
        }

        let filled = secondRow.count == maxNumberOfButtonsPerRow
        let referenceButton = firstRow.count > 1 ? firstRow[1] : firstRow[0]

        constraints.append(contentsOf: constrainRowOfButtons(
            secondRow,
            inset: InputBarRowConstants.buttonsBarHeight,
            rowIsFull: filled,
            referenceButton: referenceButton
        ))

        setupAccessibility()
    }

    private func setupButtonContainer() {
        buttonInnerContainer.removeSubviews()

        for button in buttons {
            button.removeRoundedCorners()
            button.removeFromSuperview()
            buttonInnerContainer.addSubview(button)
        }
    }

    private func determineButtonLayout() -> (firstRow: [UIButton], secondRow: [UIButton], isMultilineLayout: Bool) {
        let minButtonWidth = InputBarRowConstants.minimumButtonWidth(forWidth: bounds.width)
        let maxNumberOfButtonsPerRow = Int(floor(Float(bounds.width / minButtonWidth)))
        let isMultilineLayout = buttons.count > maxNumberOfButtonsPerRow

        var firstRow: [UIButton], secondRow: [UIButton]

        if isMultilineLayout {
            firstRow = Array(buttons.prefix(customButtonCount)) + [expandRowButton]
            secondRow = Array(buttons.suffix(buttons.count - customButtonCount))
        } else {
            firstRow = buttons
            secondRow = []
        }

        return (firstRow, secondRow, isMultilineLayout)
    }

    private func roundButtons(firstRow: [UIButton], secondRow: [UIButton]) {
        if firstRow.count == 1 {
            firstRow.first?.layer.cornerRadius = 12
            firstRow.first?.clipsToBounds = true
        } else {
            firstRow.first?.roundCorners(edge: .leading, radius: 12)
            firstRow.last?.roundCorners(edge: .trailing, radius: 12)
            secondRow.first?.roundCorners(edge: .leading, radius: 12)
        }
    }

    private func constrainRowOfButtons(
        _ buttons: [UIButton],
        inset: CGFloat,
        rowIsFull: Bool,
        referenceButton: UIButton?
    ) -> [NSLayoutConstraint] {
        let buttonPadding: CGFloat = 12
        let buttonHeight = InputBarRowConstants.buttonsBarHeight - buttonPadding * 2
        let offset = InputBarRowConstants.iconSize / 2 + buttonMargin
        let constraintMultiplier = 0.5

        var constraints = setupInitialConstraints(for: buttons, rowIsFull: rowIsFull, buttonPadding: buttonPadding)

        for button in buttons {
            constraints.append(
                contentsOf: constraintsForButton(
                    button,
                    in: buttons,
                    inset: inset,
                    buttonPadding: buttonPadding,
                    buttonHeight: buttonHeight
                )
            )
        }

        constraints.append(
            contentsOf: constraintsBetweenButtons(
                buttons,
                rowIsFull: rowIsFull,
                offset: offset,
                constraintMultiplier: constraintMultiplier
            )
        )

        if let reference = referenceButton, !rowIsFull {
            [reference, buttons.last!].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            constraints.append(buttons.last!.widthAnchor.constraint(equalTo: reference.widthAnchor))
        }

        setupInsets(forButtons: buttons, rowIsFull: rowIsFull)

        return constraints
    }

    private func setupInitialConstraints(
        for buttons: [UIButton],
        rowIsFull: Bool,
        buttonPadding: CGFloat
    ) -> [NSLayoutConstraint] {
        guard let firstButton = buttons.first, let lastButton = buttons.last else { return [] }

        var constraints = [NSLayoutConstraint]()
        firstButton.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(
            firstButton.leadingAnchor.constraint(
                equalTo: firstButton.superview!.leadingAnchor,
                constant: buttonPadding
            )
        )

        if rowIsFull {
            lastButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(
                lastButton.trailingAnchor.constraint(
                    equalTo: lastButton.superview!.trailingAnchor,
                    constant: -buttonPadding
                )
            )
        }

        return constraints
    }

    private func constraintsForButton(
        _ button: UIButton,
        in buttons: [UIButton],
        inset: CGFloat,
        buttonPadding: CGFloat,
        buttonHeight: CGFloat
    ) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        button.translatesAutoresizingMaskIntoConstraints = false

        if button == expandRowButton {
            constraints.append(contentsOf: [
                button.topAnchor.constraint(equalTo: topAnchor, constant: buttonPadding),
                button.heightAnchor.constraint(equalToConstant: buttonHeight),
            ])
        } else {
            buttonInnerContainer.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                button.topAnchor.constraint(equalTo: buttonInnerContainer.topAnchor, constant: inset + buttonPadding),
                button.heightAnchor.constraint(equalToConstant: buttonHeight),
            ])
        }

        return constraints
    }

    private func constraintsBetweenButtons(
        _ buttons: [UIButton],
        rowIsFull: Bool,
        offset: CGFloat,
        constraintMultiplier: CGFloat
    ) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        var previous: UIButton = buttons.first!

        for current: UIButton in buttons.dropFirst() {
            let isFirstButton = previous == buttons.first
            let isLastButton = rowIsFull && current == buttons.last

            [previous, current].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            constraints.append(previous.trailingAnchor.constraint(equalTo: current.leadingAnchor))

            if isFirstButton {
                constraints.append(
                    previous.widthAnchor.constraint(
                        equalTo: current.widthAnchor,
                        multiplier: constraintMultiplier,
                        constant: offset
                    )
                )
            } else if isLastButton {
                constraints.append(
                    current.widthAnchor.constraint(
                        equalTo: previous.widthAnchor,
                        multiplier: constraintMultiplier,
                        constant: offset
                    )
                )
            } else {
                constraints.append(
                    current.widthAnchor.constraint(equalTo: previous.widthAnchor)
                )
            }

            previous = current
        }

        return constraints
    }

    private func setupInsets(for button: UIButton, position: ButtonPosition) {
        let labelSize = button.titleLabel!.intrinsicContentSize
        let iconSize = InputBarRowConstants.iconSize
        let topMargin = InputBarRowConstants.titleTopMargin
        let titleMargin = (conversationHorizontalMargins.left / 2) - iconSize - (labelSize.width / 2)

        switch position {
        case .first:
            button.titleEdgeInsets = UIEdgeInsets(
                top: iconSize + labelSize.height + topMargin,
                left: titleMargin,
                bottom: 0,
                right: 0
            )

        case .last:
            let rightMargin = titleMargin - 1 // Adjust as needed for the last button
            button.titleEdgeInsets = UIEdgeInsets(
                top: iconSize + labelSize.height + topMargin,
                left: 0,
                bottom: 0,
                right: rightMargin
            )
            button.titleLabel?.lineBreakMode = .byClipping

        case .middle:
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -labelSize.width)
            button.titleEdgeInsets = UIEdgeInsets(
                top: iconSize + labelSize.height + topMargin,
                left: -iconSize,
                bottom: 0,
                right: 0
            )
        }

        button.contentHorizontalAlignment = .center
        button.imageView?.contentMode = .center
    }

    private func setupInsets(forButtons buttons: [UIButton], rowIsFull: Bool) {
        guard !buttons.isEmpty else { return }

        setupInsets(for: buttons.first!, position: .first)

        if rowIsFull {
            setupInsets(for: buttons.last!, position: .last)
        }

        for button in buttons.dropFirst().dropLast() {
            setupInsets(for: button, position: .middle)
        }
    }

    // MARK: - Actions

    private func anyButtonPressed() {
        showRow(0, animated: true)
    }

    private func ellipsisButtonPressed() {
        showRow(currentRow == 0 ? 1 : 0, animated: true)
    }
}
