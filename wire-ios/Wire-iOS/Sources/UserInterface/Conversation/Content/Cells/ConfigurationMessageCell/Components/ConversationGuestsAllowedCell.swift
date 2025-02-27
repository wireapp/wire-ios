//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class GuestsAllowedCellDescription: ConversationMessageCellDescription {

    // MARK: Properties

    typealias View = GuestsAllowedCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: CGFloat = 16

    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    // MARK: initialization

    init() {
        self.configuration = View.Configuration()
        self.actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}

// MARK: GuestAllowedCell

final class GuestsAllowedCell: UIView, ConversationMessageCell {

    // MARK: Properties

    typealias Configuration = Void

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    let inviteButton = SecondaryTextButton()
    var isSelected: Bool = false

    // MARK: initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI

    private func setupViews() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        [titleLabel, inviteButton].forEach(stackView.addArrangedSubview)
        titleLabel.numberOfLines = 0
        titleLabel.text = L10n.Localizable.Content.System.Conversation.Invite.title
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.font = FontSpec.mediumFont.font!

        inviteButton.setTitle(L10n.Localizable.Content.System.Conversation.Invite.button, for: .normal)
        inviteButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)
    }

    private func createConstraints() {
        let margins = conversationHorizontalMargins

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: margins.right),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    // MARK: Configuration and actions

    func configure(with object: Configuration, animated: Bool) {}

    @objc
    private func inviteButtonTapped(_ sender: UIButton) {
        delegate?.conversationMessageWantsToOpenGuestOptionsFromView(self, sourceView: self)
    }

}
