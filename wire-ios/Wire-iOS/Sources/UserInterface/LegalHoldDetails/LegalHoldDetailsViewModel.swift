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
import WireSyncEngine

struct LegalHoldDetailsViewModel {

    struct Header {
        let title: String
        let description: String
    }

    struct ParticipantsSection {
        let participants: [UserType]
        let accessibilityIdentifier: String

        var title: String {
            L10n.Localizable.Legalhold.Participants.Section.title(participants.count).localizedUppercase
        }
    }

    enum Action {
        case verifyLegalHoldSubjects
    }

    let conversation: LegalHoldDetailsConversation
    let selfUser: UserType?

    var navigationTitle: String {
        L10n.Localizable.Legalhold.Header.title
    }

    var closeButtonAccessibilityLabel: String {
        L10n.Localizable.General.close
    }

    var header: Header {
        Header(
            title: L10n.Localizable.Legalhold.Header.title,
            description: selfUser?.isUnderLegalHold == true
                ? L10n.Localizable.Legalhold.Header.selfDescription
                : L10n.Localizable.Legalhold.Header.otherDescription
        )
    }

    var participantsSection: ParticipantsSection {
        ParticipantsSection(
            participants: conversation.sortedActiveParticipantsUserTypes.filter(\.isUnderLegalHold),
            accessibilityIdentifier: "label.groupdetails.participants"
        )
    }

    var viewDidAppearAction: Action? {
        conversation is ZMConversation ? .verifyLegalHoldSubjects : nil
    }

    func shouldReloadParticipantsSection(for changeInfo: UserChangeInfo) -> Bool {
        changeInfo.connectionStateChanged || changeInfo.nameChanged || changeInfo.isUnderLegalHoldChanged
    }

}
