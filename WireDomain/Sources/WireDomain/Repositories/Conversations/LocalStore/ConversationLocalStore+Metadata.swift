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

import WireDataModel
import WireNetwork

/// An extension that encapsulates storage operations related to conversation metadata.

extension ConversationLocalStore {

    // MARK: - Metadata

    func updateMetadata(
        from conversation: Conversation,
        for localConversation: ZMConversation
    ) {
        if let teamID = conversation.teamID {
            localConversation.updateTeam(identifier: teamID)
        }

        if let name = conversation.name {
            localConversation.userDefinedName = name
        }

        guard let userID = conversation.creator else {
            return
        }

        /// We assume that the creator always belongs to the same domain as the conversation
        let creator = ZMUser.fetchOrCreate(
            with: userID,
            domain: conversation.qualifiedID?.domain,
            in: context
        )

        localConversation.creator = creator
    }

    // MARK: - Attributes

    func updateAttributes(
        from conversation: Conversation,
        for localConversation: ZMConversation,
        isFederationEnabled: Bool
    ) {
        localConversation.domain = isFederationEnabled ? conversation.qualifiedID?.domain : nil
        localConversation.needsToBeUpdatedFromBackend = false

        if let epoch = conversation.epoch {
            localConversation.epoch = UInt64(epoch)
        }

        let base64String = conversation.mlsGroupID

        if let base64String, let mlsGroupID = MLSGroupID(base64Encoded: base64String) {
            localConversation.mlsGroupID = mlsGroupID
        }

        let ciphersuite = conversation.cipherSuite
        let epoch = conversation.epoch

        if let ciphersuite, let epoch, epoch > 0 {
            localConversation.ciphersuite = ciphersuite
        }
    }

    // MARK: - Timestamps

    func updateConversationTimestamps(
        for localConversation: ZMConversation,
        serverTimestamp: Date
    ) {
        /// If the lastModifiedDate is non-nil, e.g. restore from backup,
        /// do not update the lastModifiedDate.

        if localConversation.lastModifiedDate == nil {
            localConversation.updateLastModified(serverTimestamp)
        }

        localConversation.updateServerModified(serverTimestamp)
    }

}
