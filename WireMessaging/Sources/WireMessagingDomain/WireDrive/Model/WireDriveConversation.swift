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
import UIKit

/// A conversation with enabled Drive.
/// Wire Drive file nodes are linked to one of this conversations.
public struct WireDriveConversation: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let kind: Kind?
    public let participants: Set<WireDriveParticipant>

    public init(
        id: String,
        name: String,
        kind: Kind? = nil,
        participants: Set<WireDriveParticipant>
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.participants = participants
    }
}

public extension WireDriveConversation {
    enum Kind: Sendable {
        case group
        case channel
    }
}

public extension WireDriveConversation {
    static func mocked() -> Self {
        .init(id: UUID().uuidString, name: "Conversation 1", participants: [])
    }
}

public extension Collection<WireDriveConversation> {
    static func mocked() -> [Element] {
        [
            .init(
                id: "1234",
                name: "Conversation 1",
                participants: Set([WireDriveParticipant].mocked())
            ),
            .init(
                id: "5678",
                name: "Conversation 2",
                participants: Set([WireDriveParticipant].mocked())
            ),
            .init(
                id: "5678",
                name: "Conversation 3",
                kind: .group,
                participants: Set([WireDriveParticipant].mocked())
            )
        ]
    }
}
