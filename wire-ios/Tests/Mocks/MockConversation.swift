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

import Foundation
import WireRequestStrategy
@testable import Wire

// MARK: - SwiftMockConversation

// swiftlint:disable:next todo_requires_jira_link
// TODO: rename to MockConversation after objc MockConversation is retired
class SwiftMockConversation: NSObject, Conversation {
    var isMLSConversationDegraded = false
    var isProteusConversationDegraded = false

    var relatedConnectionState: ZMConnectionStatus = .invalid

    var sortedOtherParticipants: [UserType] = []
    var sortedServiceUsers: [UserType] = []

    func verifyLegalHoldSubjects() {
        // no-op
    }

    var sortedActiveParticipantsUserTypes: [UserType] = []

    var isSelfAnActiveMember = true

    var conversationType: ZMConversationType = .group

    var teamRemoteIdentifier: UUID?

    var mockLocalParticipantsContain = false
    func localParticipantsContain(user: UserType) -> Bool {
        mockLocalParticipantsContain
    }

    var displayName: String? = ""

    var connectedUserType: UserType?

    var allowGuests = false

    var allowServices = false

    var teamType: TeamType?

    var accessMode: ConversationAccessMode?

    var accessRole: ConversationAccessRole?

    var accessRoles: Set<ConversationAccessRoleV2> = [.teamMember]

    var isUnderLegalHold = false
    var isE2EIEnabled = false
    var securityLevel: ZMConversationSecurityLevel = .notSecure

    var mutedMessageTypes: MutedMessageTypes = .none

    var localParticipantsCount = 0
    var lastMessage: ZMConversationMessage?
    var firstUnreadMessage: ZMConversationMessage?

    var areServicesPresent = false

    var domain: String?

    var ciphersuite: WireDataModel.MLSCipherSuite? = .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
}

// MARK: - MockGroupDetailsConversation

final class MockGroupDetailsConversation: SwiftMockConversation, GroupDetailsConversation {
    var userDefinedName: String?

    var freeParticipantSlots = 1

    var hasReadReceiptsEnabled = false

    var syncedMessageDestructionTimeout: TimeInterval = 0

    var messageProtocol: MessageProtocol = .proteus

    var mlsGroupID: MLSGroupID?

    var mlsVerificationStatus: MLSVerificationStatus?
}

// MARK: - MockInputBarConversationType

final class MockInputBarConversationType: SwiftMockConversation, InputBarConversation, TypingStatusProvider {
    var typingUsers: [UserType] = []

    var hasDraftMessage = false

    var draftMessage: DraftMessage?

    func setIsTyping(_: Bool) {
        // no-op
    }

    var isReadOnly = false

    var participants: [UserType] = []

    var activeMessageDestructionTimeoutValue: MessageDestructionTimeoutValue?
    var hasSyncedMessageDestructionTimeout = false
    var isSelfDeletingMessageSendingDisabled = false
    var isSelfDeletingMessageTimeoutForced = false
}
