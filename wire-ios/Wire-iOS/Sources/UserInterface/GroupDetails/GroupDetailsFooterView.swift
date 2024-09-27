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
import WireDataModel

// MARK: - GroupDetailsFooterViewDelegate

protocol GroupDetailsFooterViewDelegate: AnyObject {
    func footerView(_ view: GroupDetailsFooterView, shouldPerformAction action: GroupDetailsFooterView.Action)
}

// MARK: - GroupDetailsFooterView

final class GroupDetailsFooterView: ConversationDetailFooterView {
    enum Action {
        case more
        case invite
    }

    weak var delegate: GroupDetailsFooterViewDelegate?

    func update(for conversation: GroupDetailsConversationType) {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        leftButton.isHidden = !user.canAddUser(to: conversation)
        leftButton.isEnabled = conversation.freeParticipantSlots > 0
    }

    override func setupButtons() {
        leftIcon = .plus
        leftButton.setTitle(L10n.Localizable.Participants.Footer.addTitle, for: .normal)
        leftButton.accessibilityIdentifier = "OtherUserMetaControllerLeftButton"
        rightIcon = .ellipsis
        rightButton.accessibilityIdentifier = "OtherUserMetaControllerRightButton"
        rightButton.accessibilityLabel = L10n.Accessibility.ConversationDetails.MoreButton.description
    }

    override func leftButtonTapped(_: IconButton) {
        delegate?.footerView(self, shouldPerformAction: .invite)
    }

    override func rightButtonTapped(_: IconButton) {
        delegate?.footerView(self, shouldPerformAction: .more)
    }
}
