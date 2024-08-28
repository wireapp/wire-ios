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

/// An extension that encapsulates storage work related to conversation various statuses.

extension ConversationLocalStore {

    func updateConversationStatus(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        if let selfMember = payload.members?.selfMember {
            updateMemberStatus(
                from: selfMember,
                for: conversation
            )
        }

        if let readReceiptMode = payload.readReceiptMode {
            conversation.updateReceiptMode(readReceiptMode)
        }

        if let accessModes = payload.access {
            if let accessRoles = payload.accessRoles {
                conversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            } else if
                let accessRole = payload.legacyAccessRole,
                let legacyAccessRole = accessRole.toDomainModel() {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
                conversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            }
        }

        if let messageTimer = payload.messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
        }
    }

    func updateMLSStatus(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) async {
        guard DeveloperFlag.enableMLSSupport.isOn else { return }

        await updateConversationIfNeeded(
            conversation: conversation,
            fallbackGroupID: payload.mlsGroupID.map { .init(base64Encoded: $0) } ?? nil
        )
    }

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?
    ) async {
        let (messageProtocol, mlsGroupID, mlsService) = await context.perform { [self] in
            (
                conversation.messageProtocol,
                conversation.mlsGroupID,
                context.mlsService
            )
        }

        guard
            messageProtocol.isOne(of: .mls, .mixed),
            let mlsGroupID = mlsGroupID ?? fallbackGroupID
        else {
            return
        }

        await context.perform {
            if conversation.mlsGroupID == nil {
                conversation.mlsGroupID = mlsGroupID
            }
        }

        guard let mlsService else { return }

        let conversationExists: Bool

        do {
            conversationExists = try await mlsService.conversationExists(groupID: mlsGroupID)
        } catch {
            conversationExists = false
        }

        let newStatus: MLSGroupStatus = conversationExists ? .ready : .pendingJoin

        await context.perform { [self] in
            conversation.mlsStatus = newStatus
            context.saveOrRollback()
        }
    }

    func updateMemberStatus(
        from payload: WireAPI.Conversation.Member,
        for conversation: ZMConversation
    ) {
        if let mutedStatus = payload.mutedStatus,
           let mutedReference = payload.mutedReference {
            conversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
        }

        if let archived = payload.archived,
           let archivedReference = payload.archivedReference {
            conversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
        }
    }

}
