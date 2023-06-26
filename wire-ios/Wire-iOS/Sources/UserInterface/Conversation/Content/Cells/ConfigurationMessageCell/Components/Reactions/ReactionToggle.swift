//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

// MARK: - ReactionToggle

class ReactionToggle: UIControl {

    // MARK: - Properties

    typealias ButtonColors = SemanticColors.Button

    private let emojiLabel = DynamicFontLabel(fontSpec: .mediumRegularFont,
                                              color: SemanticColors.Label.textDefault)
    private let counterLabel = DynamicFontLabel(fontSpec: .mediumSemiboldFont,
                                                color: SemanticColors.Label.textDefault)

    private var onToggle: (() -> Void)?

    var isToggled: Bool {
        didSet {
            guard oldValue != isToggled else { return }
            updateAppearance()
        }
    }

    // MARK: - Lifecycle

    init(isToggled: Bool = false) {
        self.isToggled = isToggled
        super.init(frame: .zero)

        layer.borderWidth = 1
        layer.cornerRadius = 12
        layer.masksToBounds = true

        let stackView = UIStackView(arrangedSubviews: [emojiLabel, counterLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 4

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 0)

        stackView.isUserInteractionEnabled = false

        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateAppearance()
        addTarget(self, action: #selector(didToggle), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    public func configureData(
        type: String,
        count: Int,
        isToggled: Bool,
        onToggle: @escaping () -> Void
    ) {
        emojiLabel.text  = type
        counterLabel.text = String(count)
        self.isToggled = isToggled
        self.onToggle = onToggle
    }

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
