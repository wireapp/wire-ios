//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDataModel
import WireDesign

final class FailedUsersSystemMessageCell<
    CellDescription: ConversationMessageCellDescription
>: UIView, ConversationMessageCell {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants

    struct Configuration {
        let title: NSAttributedString?
        let content: NSAttributedString
        let isCollapsed: Bool
        let icon: UIImage?
        let buttonAction: Completion
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = true

    private var isCollapsed: Bool = true
    private var buttonAction: Completion?

    private let contentStackView = UIStackView(axis: .vertical)
    private let stackView = UIStackView(axis: .vertical)
    private let totalCountView = WebLinkTextView()
    private let usersView = WebLinkTextView()
    private let imageContainer = UIView()
    private var imageView = UIImageView()
    private let button = SecondaryTextButton(
        fontSpec: FontSpec.buttonSmallSemibold,
        insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    )

    private var withIconConstraints: [NSLayoutConstraint] = []
    private var withoutIconConstraints: [NSLayoutConstraint] = []
    private var currentIconPresent: Bool?

    private var config: Configuration? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: - Setup UI

    func configure(with object: Configuration, animated: Bool) {
        config = object
    }

    private func updateUI() {
        guard let config else {
            return
        }

        isCollapsed = config.isCollapsed
        buttonAction = config.buttonAction
        imageView.image = config.icon?.withTintColor(SemanticColors.Label.textErrorDefault)

        let iconPresent = config.icon != nil
        if currentIconPresent != iconPresent {
            currentIconPresent = iconPresent
            if iconPresent {
                NSLayoutConstraint.deactivate(withoutIconConstraints)
                NSLayoutConstraint.activate(withIconConstraints)
            } else {
                NSLayoutConstraint.deactivate(withIconConstraints)
                NSLayoutConstraint.activate(withoutIconConstraints)
            }
        }

        guard let title = config.title else {
            usersView.attributedText = config.content
            [totalCountView, button].forEach { $0.isHidden = true }
            return
        }

        [totalCountView, button].forEach { $0.isHidden = false }
        usersView.isHidden = isCollapsed
        totalCountView.attributedText = title
        usersView.attributedText = config.content
        setupButtonTitle()

        layoutIfNeeded()
    }

    private func setupButtonTitle() {
        let buttonTitle = isCollapsed ? FailedtosendParticipants.showDetails : FailedtosendParticipants.hideDetails
        button.setTitle(buttonTitle, for: .normal)
    }

    private func setupViews() {
        addSubview(stackView)

        contentStackView.alignment = .leading
        contentStackView.spacing = 2
        usersView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        [totalCountView, usersView].forEach(contentStackView.addArrangedSubview)

        stackView.alignment = .leading
        stackView.spacing = 8
        [contentStackView, button].forEach(stackView.addArrangedSubview)

        button.setTitle(FailedtosendParticipants.showDetails, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        imageContainer.addSubview(imageView)
        addSubview(imageContainer)

        createConstraints()
        setupAccessibility()
    }

    private func createConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        totalCountView.translatesAutoresizingMaskIntoConstraints = false
        usersView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        let margins = conversationHorizontalMargins

        withIconConstraints = [
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            imageContainer.widthAnchor.constraint(equalToConstant: 32),
            stackView.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margins.right)
        ]

        withoutIconConstraints = [
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: 0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageContainer.topAnchor.constraint(equalTo: stackView.topAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageView.heightAnchor),

            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
        ])
    }

    private func setupAccessibility() {
        totalCountView.accessibilityIdentifier = "total_count.label"
        usersView.accessibilityIdentifier = "users_list.label"
        button.accessibilityIdentifier = "details.button"
    }

    // MARK: - Methods

    @objc
    func buttonTapped(_ sender: UIButton) {
        buttonAction?()
    }

}
