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

enum ImageToolbarConfiguration {
    case cell
    case compactCell
    case preview
}

final class ImageToolbarView: UIView {
    let buttonContainer = UIView()
    let sketchButton = IconButton()
    let emojiButton = IconButton()
    let textButton = IconButton()
    let expandButton = IconButton()
    var buttons: [IconButton] = []

    var configuration: ImageToolbarConfiguration {
        didSet {
            guard oldValue != configuration else { return }

            updateButtonConfiguration()
        }
    }

    var showsSketchButton = true {
        didSet {
            guard oldValue != showsSketchButton else { return }
            updateButtonConfiguration()
        }
    }

    var imageIsEphemeral = false {
        didSet {
            guard oldValue != imageIsEphemeral else { return }
            updateButtonConfiguration()
        }
    }

    var isPlacedOnImage: Bool = false {
        didSet {
            backgroundColor = isPlacedOnImage ? UIColor(white: 0, alpha: 0.40) : UIColor.clear
            updateButtonStyle()
        }
    }

    private func updateButtonStyle() {
        let normalColor: UIColor = isPlacedOnImage ? .from(scheme: .iconNormal, variant: .dark) : .from(scheme: .iconNormal)
        let highlightedColor: UIColor = isPlacedOnImage ? .from(scheme: .iconHighlighted, variant: .dark) : .from(scheme: .iconHighlighted)
        let selectedColor: UIColor = isPlacedOnImage ? .accentDarken : .accent()

        for item in [sketchButton, emojiButton, textButton, expandButton] {
            item.setIconColor(normalColor, for: .normal)
            item.setIconColor(highlightedColor, for: .highlighted)
            item.setIconColor(selectedColor, for: .selected)
        }
    }

    init(withConfiguraton configuration: ImageToolbarConfiguration) {
        self.configuration = configuration

        super.init(frame: CGRect.zero)

        updateButtonStyle()

        addSubview(buttonContainer)

        createConstraints()

        setupButtons()
        updateButtonConfiguration()
    }

    private func createConstraints() {
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonContainer.topAnchor.constraint(equalTo: topAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonContainer.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            buttonContainer.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateButtonConfiguration() {
        buttons.forEach({ $0.removeFromSuperview() })
        var newButtons = showsSketchButton ? [sketchButton] : []

        switch configuration {
        case .cell where imageIsEphemeral, .compactCell where imageIsEphemeral:
            // ephemeral images should only expand
            newButtons = [expandButton]
        case .cell:
            newButtons.append(contentsOf: [emojiButton, expandButton])
        case .compactCell:
            newButtons.append(expandButton)
        case .preview:
            newButtons.append(emojiButton)
        }

        buttons = newButtons
        buttons.forEach(buttonContainer.addSubview)
        createButtonConstraints()
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: Bill - use stack view to hold the buttons?
    private func createButtonConstraints() {
        let spacing: CGFloat = 16

        var constraints: [NSLayoutConstraint] = []

        if let firstButton = buttons.first {
            firstButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(
                firstButton.leftAnchor.constraint(equalTo: buttonContainer.leftAnchor, constant: spacing)
            )
        }

        if let lastButton = buttons.last {
            lastButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(
                lastButton.rightAnchor.constraint(equalTo: buttonContainer.rightAnchor, constant: -spacing)
            )
        }

        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                button.widthAnchor.constraint(equalToConstant: 16),
                button.heightAnchor.constraint(equalToConstant: 16),
                button.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor)
            ])
        }

        for i in 1..<buttons.count {
            let previousButton = buttons[i - 1]
            let button = buttons[i]

            [button, previousButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            constraints.append(
                button.leftAnchor.constraint(equalTo: previousButton.rightAnchor, constant: spacing * 2)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupButtons() {
        let hitAreaPadding = CGSize(width: 16, height: 16)

        sketchButton.setIcon(.brush, size: .tiny, for: .normal)
        sketchButton.hitAreaPadding = hitAreaPadding
        sketchButton.accessibilityIdentifier = "sketchButton"

        emojiButton.setIcon(.emoji, size: .tiny, for: .normal)
        emojiButton.hitAreaPadding = hitAreaPadding
        emojiButton.accessibilityIdentifier = "emojiButton"

        textButton.setIcon(.pencil, size: .tiny, for: .normal)
        textButton.hitAreaPadding = hitAreaPadding
        textButton.accessibilityIdentifier = "textButton"

        expandButton.setIcon(.fullScreen, size: .tiny, for: .normal)
        expandButton.hitAreaPadding = hitAreaPadding
        expandButton.accessibilityIdentifier = "expandButton"
    }
}
