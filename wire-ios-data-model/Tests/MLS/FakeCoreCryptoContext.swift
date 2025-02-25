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

import WireCoreCrypto

// Stub to replace corecryptoContext. This is temporary to test transactional API, a more robust solution should be provided
final class FakeCoreCryptoContext: WireCoreCrypto.CoreCryptoContext {

    var decryptMessageConversationIdPayload_Invocations: [(conversationId: Data, payload: Data)] = []

    var decryptMessage: (WireCoreCrypto.DecryptedMessage?, Error?)?

    override func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCrypto.DecryptedMessage {
        decryptMessageConversationIdPayload_Invocations.append((conversationId, payload))

        if let message = decryptMessage?.0 {
            return message
        }
        if let error = decryptMessage?.1 {
            throw error
        }
        fatalError("missing mock for decryptMessage(conversationId:payload:")
    }
}
