//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import CoreCryptoSwift

class CoreCryptoCallbacksImpl: CoreCryptoCallbacks {

    init() {}

    func authorize(conversationId: ConversationId, clientId: ClientId) -> Bool {
        // Currently not neccessary because backend is already validated proposals.
        // In the future, method may be useful for proposals that the backend can't
        // inspect.
        return true
    }

    func userAuthorize(conversationId: ConversationId, externalClientId: ClientId, existingClients: [ClientId]) -> Bool {
        // TODO: Check with core crypto team what the implementation should be
        return true
    }

    func clientIsExistingGroupUser(
        conversationId: ConversationId,
        clientId: ClientId,
        existingClients: [ClientId]
    ) -> Bool {
        guard let mlsClientID = MLSClientID(data: clientId.data) else {
            return false
        }

        let existingClientIDs = existingClients.compactMap {
            MLSClientID(data: $0.data)
        }

        return existingClientIDs.contains {
            // Does `existingClients` contain a client belonging to the same owner of `clientId`?
            $0.userID == mlsClientID.userID && $0.domain == mlsClientID.domain
        }
    }

}
