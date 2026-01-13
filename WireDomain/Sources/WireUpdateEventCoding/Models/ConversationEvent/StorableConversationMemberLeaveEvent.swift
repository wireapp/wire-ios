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

struct StorableConversationMemberLeaveEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let timestamp: Date
    private let removedUserIDs: [StorableQualifiedID]
    private let reason: StorableConversationMemberLeaveReason

    init(_ value: WireNetwork.ConversationMemberLeaveEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.timestamp = value.timestamp
        self.removedUserIDs = value.removedUserIDs.map(StorableQualifiedID.init)
        self.reason = StorableConversationMemberLeaveReason(value.reason)
    }

    func toAPIModel() -> WireNetwork.ConversationMemberLeaveEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp,
            removedUserIDs: removedUserIDs.map { $0.toAPIModel() }.toSet(),
            reason: reason.toAPIModel()
        )
    }

}

private enum StorableConversationMemberLeaveReason: String, Codable, Sendable {

    case userDeleted
    case userLeft
    case userRemoved

    init(_ value: WireNetwork.ConversationMemberLeaveReason) {
        switch value {
        case .userDeleted:
            self = .userDeleted
        case .userLeft:
            self = .userLeft
        case .userRemoved:
            self = .userRemoved
        }
    }

    func toAPIModel() -> WireNetwork.ConversationMemberLeaveReason {
        switch self {
        case .userDeleted:
            .userDeleted
        case .userLeft:
            .userLeft
        case .userRemoved:
            .userRemoved
        }
    }

}
