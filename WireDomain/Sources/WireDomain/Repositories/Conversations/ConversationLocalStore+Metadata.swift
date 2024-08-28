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

/// An extension that encapsulates storage work related to conversation metadata.

extension ConversationLocalStore {

    // MARK: - Metadata

    func updateMetadata(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        if let teamID = payload.teamID {
            conversation.updateTeam(identifier: teamID)
        }

        if let name = payload.name {
            conversation.userDefinedName = name
        }

        guard let userID = payload.creator else {
            return
        }

        /// We assume that the creator always belongs to the same domain as the conversation
        let creator = ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )

        conversation.creator = creator
    }

    // MARK: - Attributes

    func updateAttributes(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false

        if let epoch = payload.epoch {
            conversation.epoch = UInt64(epoch)
        }

        if
            let base64String = payload.mlsGroupID,
            let mlsGroupID = MLSGroupID(base64Encoded: base64String) {
            conversation.mlsGroupID = mlsGroupID
        }

        if let ciphersuite = payload.cipherSuite, let epoch = payload.epoch, epoch > 0 {
            conversation.ciphersuite = ciphersuite.toDomainModel()
        }
    }

    // MARK: - Timestamps

    func updateConversationTimestamps(
        for conversation: ZMConversation
    ) {
        /// If the lastModifiedDate is non-nil, e.g. restore from backup,
        /// do not update the lastModifiedDate.

        let serverTimestamp = Date.now

        if conversation.lastModifiedDate == nil {
            conversation.updateLastModified(serverTimestamp)
        }

        conversation.updateServerModified(serverTimestamp)
    }

}
