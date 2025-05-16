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

import Foundation

public struct MessageModel: Equatable {
    public let nonce: UUID?
    public let sender: UserModel?
    public let systemMessageType: SystemMessageTypeModel?
    public let updatedAt: Date?
    public let receivedAt: Date?
    public let expirationReason: ExpirationReasonModel?
    public let conversationType: ConversationTypeModel?
    public let readReceiptsCount: Int
    public let deliveryState: DeliveryStateModel
    public let isSent: Bool

    public init(
        nonce: UUID?,
        sender: UserModel?,
        systemMessageType: SystemMessageTypeModel?,
        updatedAt: Date?,
        receivedAt: Date?,
        expirationReason: ExpirationReasonModel?,
        conversationType: ConversationTypeModel?,
        readReceiptsCount: Int,
        deliveryState: DeliveryStateModel,
        isSent: Bool
    ) {
        self.nonce = nonce
        self.sender = sender
        self.systemMessageType = systemMessageType
        self.updatedAt = updatedAt
        self.receivedAt = receivedAt
        self.expirationReason = expirationReason
        self.conversationType = conversationType
        self.readReceiptsCount = readReceiptsCount
        self.deliveryState = deliveryState
        self.isSent = isSent
    }
}

public enum SystemMessageTypeModel: Int, Equatable {
    case invalid = 0
    case participantsAdded
    case failedToAddParticipants
    case participantsRemoved
    case conversationNameChanged
    case connectionRequest // deprecated
    case connectionUpdate  // deprecated
    case missedCall
    case newClient
    case ignoredClient
    case conversationIsSecure
    case potentialGap
    case decryptionFailed
    case decryptionFailedRemoteIdentityChanged
    case newConversation
    case reactivatedDevice // deprecated: Devices can't be reactivated any longer
    case usingNewDevice    // deprecated: We don't need inform users about new devices any longer
    case messageDeletedForEveryone
    case performedCall     // deprecated: [WPB-6988] we don't show end call messages any longer.
    case teamMemberLeave
    case messageTimerUpdate
    case readReceiptsEnabled
    case readReceiptsDisabled
    case readReceiptsOn
    case legalHoldEnabled
    case legalHoldDisabled
    case sessionReset
    case decryptionFailedResolved
    case domainsStoppedFederating
    case conversationIsVerified
    case conversationIsDegraded
    case mlsMigrationFinalized
    case mlsMigrationJoinAfterwards
    case mlsMigrationOngoingCall
    case mlsMigrationStarted
    case mlsMigrationUpdateVersion
    case mlsMigrationPotentialGap
    case mlsNotSupportedSelfUser
    case mlsNotSupportedOtherUser
}

public enum DeliveryStateModel: Int, Sendable, Equatable, CaseIterable {
    case invalid
    case pending
    case sent
    case delivered
    case read
    case failedToSend
}

@frozen
public enum ExpirationReasonModel: Int {
    case other = 0
    case federationRemoteError
    case cancelled
    case timeout
}

public enum ConversationTypeModel: Int, Codable, Sendable {

    /// A conversation with many participants.
    case group = 0

    /// A conversation with only the self user.
    case `self` = 1

    /// A conversation between the two users.
    case oneOnOne = 2

    /// A placeholder conversation for a pending connection
    /// to another user.
    case connection = 3
}
