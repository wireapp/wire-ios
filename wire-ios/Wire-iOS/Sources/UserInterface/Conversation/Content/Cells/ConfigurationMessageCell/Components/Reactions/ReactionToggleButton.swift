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

class ReactionToggleButton: UIControl {

    // MARK: - Properties

    typealias ButtonColors = SemanticColors.Button

    private let emojiLabel = DynamicFontLabel(fontSpec: .mediumRegularFont,
                                      color: SemanticColors.Label.textDefault)
    private let counterLabel = DynamicFontLabel(fontSpec: .mediumSemiboldFont,
                                        color: SemanticColors.Label.textDefault)

    var isToggled: Bool {
        didSet {
            guard oldValue != isToggled else { return }
            updateAppearance()
        }
    }

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

    public func configureData(type: String, count: Int) {
        emojiLabel.text  = type
        counterLabel.text = String(count)
    }

    private func updateAppearance() {
        backgroundColor = isToggled
        ? ButtonColors.backgroundReactionSelected :
        ButtonColors.backroundReactionNormal

        layer.borderColor = isToggled
        ? ButtonColors.borderReactionSelected.cgColor :
        ButtonColors.borderReactionNormal.cgColor

        counterLabel.textColor = isToggled
        ? SemanticColors.Label.textReactionCounterSelected :
        SemanticColors.Label.textDefault
    }

    @objc
    private func didToggle() {
        isToggled.toggle()
    }

}
