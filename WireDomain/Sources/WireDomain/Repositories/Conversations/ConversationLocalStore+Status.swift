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

/// An extension that encapsulates storage operations related to conversation statuses.

extension ConversationLocalStore {

    // MARK: - Conversation status

    func updateConversationStatus(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) {
        if let selfMember = remoteConversation.members?.selfMember {
            updateMemberStatus(
                from: selfMember,
                for: localConversation
            )
        }

        if let readReceiptMode = remoteConversation.readReceiptMode {
            localConversation.updateReceiptMode(readReceiptMode)
        }

        if let accessModes = remoteConversation.access {
            if let accessRoles = remoteConversation.accessRoles {
                localConversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            } else if let accessRole = remoteConversation.legacyAccessRole {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(accessRole.toDomainModel())
                localConversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            }
        }

        if let messageTimer = remoteConversation.messageTimer {
            localConversation.updateMessageDestructionTimeout(timeout: messageTimer)
        }
    }

    // MARK: - MLS status

    func updateMLSStatus(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) async {
        guard DeveloperFlag.enableMLSSupport.isOn else { return }

        await updateConversationIfNeeded(
            localConversation: localConversation,
            fallbackGroupID: remoteConversation.mlsGroupID.map { .init(base64Encoded: $0) } ?? nil
        )
    }

    // MARK: - MLS status

    func updateConversationIfNeeded(
        localConversation: ZMConversation,
        fallbackGroupID: MLSGroupID?
    ) async {
        let (messageProtocol, mlsGroupID) = await context.perform {
            (
                localConversation.messageProtocol,
                localConversation.mlsGroupID
            )
        }

        guard
            messageProtocol.isOne(of: .mls, .mixed),
            let mlsGroupID = mlsGroupID ?? fallbackGroupID
        else {
            return
        }

        await context.perform {
            if localConversation.mlsGroupID == nil {
                localConversation.mlsGroupID = mlsGroupID
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
            localConversation.mlsStatus = newStatus
            context.saveOrRollback()
        }
    }

    // MARK: - Member status

    func updateMemberStatus(
        from remoteConversation: WireAPI.Conversation.Member,
        for localConversation: ZMConversation
    ) {
        if let mutedStatus = remoteConversation.mutedStatus,
           let mutedReference = remoteConversation.mutedReference {
            localConversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
        }

        if let archived = remoteConversation.archived,
           let archivedReference = remoteConversation.archivedReference {
            localConversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
        }
    }

}
