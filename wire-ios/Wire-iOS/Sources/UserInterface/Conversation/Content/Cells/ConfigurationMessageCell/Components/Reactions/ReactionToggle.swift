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

// MARK: - ReactionToggle

final class ReactionToggle: UIControl {
    // MARK: Lifecycle

    init(
        emoji: Emoji.ID,
        count: UInt,
        isToggled: Bool = false,
        onToggle: (() -> Void)? = nil
    ) {
        self.isToggled = isToggled
        self.onToggle = onToggle

        super.init(frame: .zero)

        emojiLabel.text = emoji
        counterLabel.text = String(count)

        let stackView = UIStackView(arrangedSubviews: [emojiLabel, counterLabel])

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.isUserInteractionEnabled = false

        addSubview(stackView)
        stackView.fitIn(
            view: self,
            insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        )

        translatesAutoresizingMaskIntoConstraints = false

        layer.borderWidth = 1
        layer.masksToBounds = true

        updateAppearance()
        addTarget(self, action: #selector(didToggle), for: .touchUpInside)

        setupAccessibility(
            value: emoji,
            count: count
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    typealias ButtonColors = SemanticColors.Button

    var isToggled: Bool {
        didSet {
            guard oldValue != isToggled else { return }
            updateAppearance()
        }
    }

    // MARK: - Methods

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = rect.height / 2.0
    }

    // MARK: - Accessibility

    func setupAccessibility(
        value: String,
        count: UInt
    ) {
        isAccessibilityElement = true
        accessibilityIdentifier = "value: \(value), count: \(count)"
    }

    // MARK: Private

    private let emojiLabel = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Label.textDefault
    )

    private let counterLabel = DynamicFontLabel(
        fontSpec: .mediumSemiboldFont,
        color: SemanticColors.Label.textDefault
    )

    private var onToggle: (() -> Void)?

    private func updateAppearance() {
        if isToggled {
            backgroundColor = ButtonColors.backgroundReactionSelected
            layer.borderColor = ButtonColors.borderReactionSelected.cgColor
            counterLabel.textColor = SemanticColors.Label.textReactionCounterSelected
        } else {
            backgroundColor = ButtonColors.backroundReactionNormal
            layer.borderColor = ButtonColors.borderReactionNormal.cgColor
            counterLabel.textColor = SemanticColors.Label.textDefault
        }
    }

    // MARK: - Actions

    @objc
    private func didToggle() {
        onToggle?()
    }
}
