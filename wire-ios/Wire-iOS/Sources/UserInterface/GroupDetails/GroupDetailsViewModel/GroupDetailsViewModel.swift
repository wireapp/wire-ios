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

import Foundation
import WireDataModel

struct GroupDetailsViewModel {

    struct SectionsState {
        let participantSections: [GroupDetailsParticipantsState<UserType>.Section]
        let showsGroupOptions: Bool
        let showsSelfDeletingMessagesDisabled: Bool
        let showsReceiptOptions: Bool
        let showsServices: Bool
    }

    private let conversation: GroupDetailsConversationType
    private let areLegacyBotsAvailable: Bool

    init(
        conversation: GroupDetailsConversationType,
        areLegacyBotsAvailable: Bool
    ) {
        self.conversation = conversation
        self.areLegacyBotsAvailable = areLegacyBotsAvailable
    }

    func sectionsState(
        participants: [UserType],
        apps: [UserType],
        selfUser: UserType?
    ) -> SectionsState {
        let participantsState = GroupDetailsParticipantsState.make(
            participants: participants,
            isAdmin: { $0.isGroupAdmin(in: conversation) }
        )

        return SectionsState(
            participantSections: participantsState.sections,
            showsGroupOptions: showsGroupOptions(for: selfUser),
            showsSelfDeletingMessagesDisabled: conversation.isWireDriveEnabled,
            showsReceiptOptions: showsReceiptOptions(for: selfUser),
            showsServices: !apps.isEmpty
        )
    }

    private func showsGroupOptions(for user: UserType?) -> Bool {
        guard let user else { return false }

        return GroupOptionsSectionController.hasAccessibleOptions(
            in: conversation,
            by: user,
            areLegacyBotsAvailable: areLegacyBotsAvailable
        )
    }

    private func showsReceiptOptions(for user: UserType?) -> Bool {
        guard let user else { return false }

        return conversation.teamRemoteIdentifier != nil
            && user.canModifyReadReceiptSettings(in: conversation)
            && conversation.messageProtocol != .mls
    }
}
