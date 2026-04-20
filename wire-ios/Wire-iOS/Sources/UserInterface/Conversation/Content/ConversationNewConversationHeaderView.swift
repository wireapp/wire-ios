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
import WireDataModel

/// Header view shown at the start of a group or channel conversation, displaying
/// the conversation-started summary plus optional invite and Wire Drive status cells.
final class ConversationNewConversationHeaderView: UIView {

    private let stackView = UIStackView()

    var isEmpty: Bool { stackView.arrangedSubviews.isEmpty }

    weak var delegate: ConversationMessageCellDelegate? {
        didSet {
            stackView.arrangedSubviews.compactMap { $0 as? GuestsAllowedCell }.forEach {
                $0.delegate = delegate
            }
            stackView.arrangedSubviews
                .compactMap { $0 as? ConversationStartedSystemMessageCell<ConversationStartedSystemMessageCellDescription> }
                .forEach { $0.delegate = delegate }
        }
    }

    init(conversation: ZMConversation, selfUser: any UserType) {
        super.init(frame: .zero)
        setupStackView()
        populate(conversation: conversation, selfUser: selfUser)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func populate(conversation: ZMConversation, selfUser: any UserType) {
        let startedCell = ConversationStartedSystemMessageCell<ConversationStartedSystemMessageCellDescription>()
        startedCell.configure(
            with: ConversationStartedSystemMessageCellDescription(conversation: conversation).configuration,
            animated: false
        )
        stackView.addArrangedSubview(startedCell)

        if selfUser.isTeamMember,
           selfUser.canAddUser(to: conversation),
           conversation.conversationType == .group,
           conversation.allowGuests {
            let guestsCell = GuestsAllowedCell()
            guestsCell.configure(with: .init(isChannel: conversation.isChannel), animated: false)
            stackView.addArrangedSubview(guestsCell)
        }

        if conversation.isWireDriveEnabled {
            let fileCollabDesc = ConversationFileCollaborationSystemMessageCellDescription()
            let fileCollabCell = ConversationWarningSystemMessageCell<ConversationFileCollaborationSystemMessageCellDescription>()
            fileCollabCell.configure(with: fileCollabDesc.configuration, animated: false)
            stackView.addArrangedSubview(fileCollabCell)

            let timerDesc = ConversationMessageTimerSystemMessageCellDescription(state: .unavailable)
            let timerCell = ConversationWarningSystemMessageCell<ConversationMessageTimerSystemMessageCellDescription>()
            timerCell.configure(with: timerDesc.configuration, animated: false)
            stackView.addArrangedSubview(timerCell)
        }
    }
}
