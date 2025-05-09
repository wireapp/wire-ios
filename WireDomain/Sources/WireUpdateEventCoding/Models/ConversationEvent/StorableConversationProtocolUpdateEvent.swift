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

import WireAPI

struct StorableConversationProtocolUpdateEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let newProtocol: StorableConversationMessageProtocol

    init(_ value: WireAPI.ConversationProtocolUpdateEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.newProtocol = StorableConversationMessageProtocol(value.newProtocol)
    }

    func toAPIModel() -> WireAPI.ConversationProtocolUpdateEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            newProtocol: newProtocol.toAPIModel()
        )
    }

}
