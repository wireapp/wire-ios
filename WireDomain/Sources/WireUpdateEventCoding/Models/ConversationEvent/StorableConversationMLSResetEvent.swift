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
import WireNetwork

struct StorableConversationMLSResetEvent: Equatable, Codable, Sendable {

    public let conversationID: StorableQualifiedID

    public let senderID: StorableQualifiedID

    private let oldMLSGroupIDBase64: String
    private let newMLSGroupIDBase64: String

    init(_ value: WireNetwork.ConversationMLSResetEvent) {
        self.oldMLSGroupIDBase64 = value.oldMLSGroupIDBase64
        self.newMLSGroupIDBase64 = value.newMLSGroupIDBase64
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
    }

    func toAPIModel() -> WireNetwork.ConversationMLSResetEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            oldMLSGroupIDBase64: oldMLSGroupIDBase64,
            newMLSGroupIDBase64: newMLSGroupIDBase64
        )
    }
}
