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
import WireSystem

/**
 * A footer view to use to display a bar of actions to perform for a conversation.
 */

class ConversationDetailFooterView: UIView {

    // MARK: - Properties
    let rightButton = IconButton()
    var leftButton: IconButton
    private let containerView = UIView()

    var leftIcon: StyleKitIcon? {
        get {
            return leftButton.icon(for: .normal)
        }
        set {
            leftButton.isHidden = (newValue == .none)
            if newValue != .none {
                leftButton.setIcon(newValue, size: .tiny, for: .normal)
            }
        }
    }

    var rightIcon: StyleKitIcon? {
        get {
            return rightButton.icon(for: .normal)
        }
        set {
            rightButton.isHidden = (newValue == .none)
            if newValue != .none {
                rightButton.setIcon(newValue, size: .tiny, for: .normal)
            }
        }
    }

    // MARK: - Initialization
    init() {
        self.leftButton = IconButton(fontSpec: .normalSemiboldFont)
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupViews() {
        let highlightedStateColor = UIColor.accent()
        let configureButton = { (button: IconButton) in
            self.containerView.addSubview(button)
            button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
            button.setTitleColor(SemanticColors.Label.textDefault, for: .normal)
            button.setIconColor(highlightedStateColor, for: .highlighted)
            button.setTitleColor(highlightedStateColor, for: .highlighted)
        }

        configureButton(leftButton)
        configureButton(rightButton)

        leftButton.setTitleImageSpacing(16)

        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)

        backgroundColor = SemanticColors.View.backgroundUserCell
        addSubview(containerView)
        addBorder(for: .top)

        setupButtons()
    }

    private func createConstraints() {
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor),

            // containerView
            containerView.heightAnchor.constraint(equalToConstant: 56),
            containerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor),

            // leftButton
            leftButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            // leftButton
            rightButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.leadingAnchor, constant: 16)
        ])
    }

    // MARK: - Events

    func setupButtons() {
        fatal("Should be overridden in subclasses")
    }

    @objc func leftButtonTapped(_ sender: IconButton) {
        fatal("Should be overridden in subclasses")
    }

    @objc func rightButtonTapped(_ sender: IconButton) {
        fatal("Should be overridden in subclasses")
    }

}
