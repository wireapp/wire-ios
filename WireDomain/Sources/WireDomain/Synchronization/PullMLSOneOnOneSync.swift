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
import WireNetwork

public struct PullMLSOneOnOneSync: PullMLSOneOnOneSyncProtocol {

    private let api: any ConversationsAPI
    private let store: any ConversationLocalStoreProtocol
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool

    public init(
        api: any ConversationsAPI,
        store: any ConversationLocalStoreProtocol,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool
    ) {
        self.api = api
        self.store = store
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
    }

    public func pull(
        userID: UUID,
        userDomain: String
    ) async throws -> (MLSGroupID, MLSPublicKeys?) {
        let (conversation, publicKeys) = try await api.getMLSOneToOneConversation(
            userID: userID.transportString(),
            in: userDomain
        )

        guard
            let rawMLSGroupID = conversation.mlsGroupID,
            let mlsGroupID = MLSGroupID(base64Encoded: rawMLSGroupID)
        else {
            throw PullMLSOneOnOneSyncError.mlsConversationMissingGroupID
        }

        await store.storeConversation(
            conversation.toDomainModel(),
            timestamp: .now,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled
        )

        return (mlsGroupID, publicKeys)
    }

}
