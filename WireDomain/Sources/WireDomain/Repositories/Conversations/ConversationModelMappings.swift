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

import WireAPI
import WireDataModel

extension WireAPI.MLSCipherSuite {

    func toDomainModel() -> WireDataModel.MLSCipherSuite {
        switch self {
        case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
            .MLS_128_DHKEMP256_AES128GCM_SHA256_P256
        case .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
            .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
        case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448:
            .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448
        case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
            .MLS_256_DHKEMP521_AES256GCM_SHA512_P521
        case .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
            .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448
        case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
            .MLS_256_DHKEMP384_AES256GCM_SHA384_P384
        }
    }
}

extension WireAPI.ConversationAccessRoleLegacy {

    func toDomainModel() -> WireDataModel.ConversationAccessRole {
        switch self {
        case .private:
            .private
        case .team:
            .team
        case .activated:
            .activated
        case .nonActivated:
            .nonActivated
        }
    }
}

extension WireAPI.ConversationMessageProtocol {

    func toDomainModel() -> WireDataModel.MessageProtocol {
        switch self {
        case .proteus:
            .proteus
        case .mixed:
            .mixed
        case .mls:
            .mls
        }
    }

}

extension WireAPI.ConversationMemberLeaveReason {

    func toDomainModel() -> ZMSystemMessageType {
        switch self {
        case .userDeleted, .userLeft:
            .teamMemberLeave
        case .userRemoved:
            .participantsRemoved
        }
    }
}

extension WireAPI.ConversationType {

    func toDomainModel() -> WireDataModel.BackendConversationType {
        switch self {
        case .group:
            .group
        case .self:
            .`self`
        case .oneOnOne:
            .oneOnOne
        case .connection:
            .connection
        }
    }

}

extension WireAPI.Conversation.Members {

    func toDomainModel() -> WireDomain.Conversation.Members {
        .init(
            others: others.map { $0.toDomainModel() },
            selfMember: selfMember.toDomainModel()
        )
    }

}

extension WireAPI.Conversation.Member {

    func toDomainModel() -> WireDomain.Conversation.Members.Member {
        .init(
            qualifiedID: qualifiedID?.toDomainModel(),
            id: id,
            qualifiedTarget: qualifiedTarget?.toDomainModel(),
            target: target,
            conversationRole: conversationRole,
            service: service.map { .init(id: $0.id, provider: $0.provider) },
            archived: archived,
            archivedReference: archivedReference,
            hidden: hidden,
            hiddenReference: hiddenReference,
            mutedStatus: mutedStatus,
            mutedReference: mutedReference
        )
    }

}

extension WireAPI.Conversation {

    func toDomainModel() -> WireDomain.Conversation {
        .init(
            id: id,
            qualifiedID: qualifiedID?.toDomainModel(),
            teamID: teamID,
            type: type?.toDomainModel(),
            messageProtocol: messageProtocol?.toDomainModel(),
            mlsGroupID: mlsGroupID,
            cipherSuite: cipherSuite?.toDomainModel(),
            epoch: epoch,
            epochTimestamp: epochTimestamp,
            creator: creator,
            members: members?.toDomainModel(),
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access?.map(\.rawValue),
            accessRoles: accessRoles?.map(\.rawValue),
            legacyAccessRole: legacyAccessRole?.toDomainModel(),
            lastEvent: lastEvent,
            lastEventTime: lastEventTime
        )
    }

}
