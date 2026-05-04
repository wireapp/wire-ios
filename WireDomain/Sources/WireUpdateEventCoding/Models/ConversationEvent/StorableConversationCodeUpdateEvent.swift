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

import WireNetwork

struct StorableConversationCodeUpdateEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let uri: String?
    private let key: String
    private let code: String
    private let isPasswordProtected: Bool

    init(_ value: WireNetwork.ConversationCodeUpdateEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.uri = value.uri
        self.key = value.key
        self.code = value.code
        self.isPasswordProtected = value.isPasswordProtected
    }

    func toAPIModel() -> WireNetwork.ConversationCodeUpdateEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            uri: uri,
            key: key,
            code: code,
            isPasswordProtected: isPasswordProtected
        )
    }

}
