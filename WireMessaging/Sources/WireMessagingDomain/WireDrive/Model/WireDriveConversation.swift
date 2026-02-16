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
public import UIKit

/// A conversation with enabled Drive.
/// Wire Drive file nodes are linked to one of this conversations.
public struct WireDriveConversation: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let kind: Kind?
    public let participants: Set<Participant>

    public init(
        id: String,
        name: String,
        kind: Kind? = nil,
        participants: Set<Participant>
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
    struct Participant: Sendable, Hashable, Identifiable {
        public let handle: String
        public let displayName: String

        public struct IconData: Sendable, Hashable {
            public let initials: String
            public let color: UIColor
            public let image: UIImage?

            public init(initials: String, color: UIColor, image: UIImage?) {
                self.initials = initials
                self.color = color
                self.image = image
            }
        }

        public let iconData: IconData?

        public init(handle: String, displayName: String, iconData: IconData? = nil) {
            self.handle = handle
            self.displayName = displayName
            self.iconData = iconData
        }

        public var id: String {
            handle // TODO: check if the handle is an appropriate ID or if we should use something else
        }
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
            .init(id: "1234", name: "Conversation 1", participants: Set([WireDriveConversation.Participant].mocked())),
            .init(id: "5678", name: "Conversation 2", participants: Set([WireDriveConversation.Participant].mocked()))
        ]
    }
}

public extension Collection<WireDriveConversation.Participant> {
    static func mocked() -> [Element] {
        [
            .init(handle: "waterwhite", displayName: "Heisenberg"),
            .init(handle: "jessepinkman", displayName: "The Cook"),
            .init(handle: "tucosalamanca", displayName: "Tuco")
        ]
    }
}
