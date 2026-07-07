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
import WireDesign

/// Header view shown at the start of a group or channel conversation, displaying
/// the conversation-started summary plus optional invite and Wire Drive status cells.
final class GroupConversationHeaderView: UIView {

    /// Shared leading inset for text content across all rows in the header.
    /// Matches the GuestAccountWarningView grid: 16 pt icon leading + 18 pt icon width + 12 pt gap.
    static let textInset: CGFloat = 46

    private let stackView = UIStackView()

    weak var delegate: ConversationMessageCellDelegate? {
        didSet {
            stackView.arrangedSubviews
                .compactMap {
                    $0 as? ConversationStartedSystemMessageCell<ConversationStartedSystemMessageCellDescription>
                }
                .forEach { $0.delegate = delegate }
        }
    }

    init(conversation: ZMConversation, selfUser: any UserType) {
        super.init(frame: .zero)
        setupStackView()
        populate(conversation: conversation, selfUser: selfUser)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

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

    private func makeGuestWarningBanner() -> UIView {
        let warningView = GuestAccountWarningView()
        warningView.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.backgroundColor = SemanticColors.View.backgroundGreen
        container.addSubview(warningView)
        warningView.fitIn(view: container, insets: .init(top: 12, left: 16, bottom: 12, right: 16))
        return container
    }

    private func populate(conversation: ZMConversation, selfUser: any UserType) {
        let bannerView = makeGuestWarningBanner()
        stackView.addArrangedSubview(bannerView)
        stackView.setCustomSpacing(16, after: bannerView)

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
            let guestsView = GuestsAllowedView(
                isChannel: conversation.isChannel,
                isWireDriveEnabled: conversation.isWireDriveEnabled
            )

            guestsView.onInviteTapped = { [weak self] in
                guard let self else { return }
                delegate?.conversationMessageWantsToOpenGuestOptionsFromView(self, sourceView: guestsView)
            }
            stackView.addArrangedSubview(guestsView)
        }

        // TODO: [WPB-18464] the sender might need to be changed to reflect the user
        // that changed the depth of the history, maybe it goes back to the conversation cells, not sure.
        if conversation.isChannel,
           let channelHistoryDepth = conversation.channelHistoryDepth,
           let creator = conversation.creator {
            let historyCell = ConversationChannelHistoryDepthSystemMessageCellDescription(
                sender: creator,
                historyDepth: channelHistoryDepth,
                isNewConversation: true
            )
            let historyView = ConversationChannelHistoryDepthSystemMessageCellDescription.View()
            historyView.configure(with: historyCell.configuration, animated: false)
            stackView.addArrangedSubview(historyView)
        }

        if conversation.isWireDriveEnabled {
            let sharedDriveDesc = ConversationSharedDriveSystemMessageCellDescription(
                selfUserRole: conversation.isTeamConversation ? .editor : .viewer
            )
            let sharedDriveCell = ConversationSharedDriveSystemMessageCellDescription.View()
            sharedDriveCell.configure(with: sharedDriveDesc.configuration, animated: false)
            stackView.addArrangedSubview(sharedDriveCell)

            let timerDescription = ConversationMessageTimerSystemMessageCellDescription(state: .unavailable)
            let timerCell = ConversationWarningSystemMessageCell<ConversationMessageTimerSystemMessageCellDescription>()
            timerCell.configure(with: timerDescription.configuration, animated: false)
            stackView.addArrangedSubview(timerCell)
        }
    }
}
