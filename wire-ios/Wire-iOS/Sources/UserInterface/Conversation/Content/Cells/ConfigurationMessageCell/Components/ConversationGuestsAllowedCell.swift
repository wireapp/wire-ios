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

final class GuestsAllowedCellDescription: ConversationMessageCellDescription {

    // MARK: Properties

    typealias View = GuestsAllowedCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    // MARK: initialization

    init(isChannel: Bool) {
        self.configuration = View.Configuration(isChannel: isChannel)
        self.actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}

// MARK: GuestAllowedCell

final class GuestsAllowedCell: UIView, ConversationMessageCell {

    // MARK: Properties

    struct Configuration: Equatable {
        let isChannel: Bool
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

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
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.font = FontSpec.mediumFont.font!

        inviteButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)

        configureTitles(isChannel: false)
    }

    private func configureTitles(isChannel: Bool) {
        typealias System = L10n.Localizable.Content.System
        titleLabel.text = isChannel ? System.Channel.Invite.title : System.Conversation.Invite.title

        let buttonTitle = isChannel ? System.Channel.Invite.button : System.Conversation.Invite.button
        inviteButton.setTitle(buttonTitle, for: .normal)
    }

    private func createConstraints() {
        let margins = conversationHorizontalMargins

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: margins.right),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    // MARK: Configuration and actions

    func configure(with object: Configuration, animated: Bool) {
        configureTitles(isChannel: object.isChannel)
    }

    @objc
    private func inviteButtonTapped(_ sender: UIButton) {
        delegate?.conversationMessageWantsToOpenGuestOptionsFromView(self, sourceView: self)
    }

}
