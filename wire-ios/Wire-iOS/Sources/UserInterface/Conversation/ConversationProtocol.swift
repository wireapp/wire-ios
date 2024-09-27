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
import WireSyncEngine

// MARK: - StableRandomParticipantsProvider

/// from UI project, to randomize users display in avatar icon
protocol StableRandomParticipantsProvider {
    var stableRandomParticipants: [UserType] { get }
}

// MARK: - ConversationStatusProvider

protocol ConversationStatusProvider {
    var status: ConversationStatus { get }
}

// MARK: - ConnectedUserProvider

protocol ConnectedUserProvider {
    var connectedUserType: UserType? { get }
}

// MARK: - TypingStatusProvider

protocol TypingStatusProvider {
    var typingUsers: [UserType] { get }
    func setIsTyping(_ isTyping: Bool)
}

// MARK: - VoiceChannelProvider

protocol VoiceChannelProvider {
    var voiceChannel: VoiceChannel? { get }
}

// MARK: - CanManageAccessProvider

protocol CanManageAccessProvider {
    var canManageAccess: Bool { get }
}

// MARK: - InputBarConversation

protocol InputBarConversation {
    var typingUsers: [UserType] { get }
    var hasDraftMessage: Bool { get }
    var draftMessage: DraftMessage? { get }

    var activeMessageDestructionTimeoutValue: MessageDestructionTimeoutValue? { get }
    var hasSyncedMessageDestructionTimeout: Bool { get }
    var isSelfDeletingMessageSendingDisabled: Bool { get }
    var isSelfDeletingMessageTimeoutForced: Bool { get }

    var isReadOnly: Bool { get }

    var participants: [UserType] { get }
    var domain: String? { get }
}

typealias InputBarConversationType = ConversationLike & InputBarConversation & TypingStatusProvider

// MARK: - ZMConversation + InputBarConversation

extension ZMConversation: InputBarConversation {
    var isSelfDeletingMessageSendingDisabled: Bool {
        guard let context = managedObjectContext else {
            return false
        }
        let feature = FeatureRepository(context: context).fetchSelfDeletingMesssages()
        return feature.status == .disabled
    }

    var isSelfDeletingMessageTimeoutForced: Bool {
        guard let context = managedObjectContext else {
            return false
        }
        let feature = FeatureRepository(context: context).fetchSelfDeletingMesssages()
        return feature.config.enforcedTimeoutSeconds > 0
    }

    var participants: [UserType] {
        Array(localParticipants) as [UserType]
    }
}

// MARK: - GroupDetailsConversation

protocol GroupDetailsConversation {
    var userDefinedName: String? { get set }

    var sortedServiceUsers: [UserType] { get }

    var allowGuests: Bool { get }
    var hasReadReceiptsEnabled: Bool { get }

    var freeParticipantSlots: Int { get }

    var teamRemoteIdentifier: UUID? { get }

    var syncedMessageDestructionTimeout: TimeInterval { get }

    var messageProtocol: MessageProtocol { get }

    var mlsGroupID: MLSGroupID? { get }

    var mlsVerificationStatus: MLSVerificationStatus? { get }

    var securityLevel: ZMConversationSecurityLevel { get }

    var isE2EIEnabled: Bool { get }
}

typealias GroupDetailsConversationType = Conversation & GroupDetailsConversation

// MARK: - ZMConversation + ConversationStatusProvider

extension ZMConversation: ConversationStatusProvider {}

// MARK: - ZMConversation + TypingStatusProvider

extension ZMConversation: TypingStatusProvider {}

// MARK: - ZMConversation + VoiceChannelProvider

extension ZMConversation: VoiceChannelProvider {}

// MARK: - ZMConversation + CanManageAccessProvider

extension ZMConversation: CanManageAccessProvider {}

// MARK: - ZMConversation + GroupDetailsConversation

extension ZMConversation: GroupDetailsConversation {
    var syncedMessageDestructionTimeout: TimeInterval {
        messageDestructionTimeoutValue(for: .groupConversation).rawValue
    }

    var isE2EIEnabled: Bool {
        guard let context = managedObjectContext else {
            return false
        }
        let feature = FeatureRepository(context: context).fetchE2EI()
        return feature.status == .enabled
    }
}

extension GroupDetailsConversation {
    var isVerified: Bool {
        switch messageProtocol {
        case .mixed,
             .proteus:
            securityLevel == .secure
        case .mls:
            isE2EIEnabled && mlsVerificationStatus == .verified
        }
    }
}
