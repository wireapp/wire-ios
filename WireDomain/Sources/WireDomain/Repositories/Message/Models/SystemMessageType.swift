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
import WireFoundation

public enum SystemMessageType: Sendable {
    case federationTermination(
        domains: [String],
        date: Date
    )

    case participantsRemovedAnonymously(
        participants: [(id: UUID, domain: String?)],
        date: Date
    )

    case participantsRemoved(
        participants: [(id: UUID, domain: String?)],
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case participantsAdded(
        participants: [(id: UUID, domain: String?)],
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case mlsMigrationMLSNotSupportedForSelfUser

    case mlsMigrationMLSNotSupportedForOtherUser(
        otherUser: (id: UUID, domain: String?)
    )

    case teamMemberRemoved(
        member: (id: UUID, domain: String?),
        date: Date
    )

    case newConversationCreated(
        date: Date
    )

    case conversationNameChanged(
        newName: String,
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case mlsMigrationStarted(
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case mlsMigrationPotentialGap(
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case mlsMigrationFinalized(
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case receiptModeIsOn(
        date: Date
    )

    case unknownMessageContentTypeReceived(
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case invalid(
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case decryptionFailed(
        sender: (id: UUID, domain: String?),
        senderClientID: String,
        remoteIdentityChanged: Bool,
        date: Date
    )

    case sessionReset(
        sender: (id: UUID, domain: String?),
        senderClientID: String,
        date: Date
    )

    case messageTimerUpdate(
        sender: (id: UUID, domain: String?),
        date: Date,
        timeoutValue: Double
    )

    case readReceiptsStatus(
        isEnabled: Bool,
        sender: (id: UUID, domain: String?),
        date: Date
    )

    case channelHistoryDepthModified(
        sender: QualifiedID
    )
}
