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

public typealias WireDriveParticipant = WireDriveConversation.Participant

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
    struct Participant: Sendable, Hashable, Identifiable {
        public let handle: String
        public let displayName: String
        public let id: String
        public let isSelfUser: Bool
        public let role: Role
        public let verificationBadges: [VerificationBadge]
        public let userType: UserType
        public let state: State
        public let iconData: IconData?

        public enum UserType: Sendable, Hashable {
            case federated
            case external
            case member
            case guest
        }

        public enum VerificationBadge: Sendable, Hashable {
            case e2EICertified
            case proteusVerified
        }

        public enum Role: String, Sendable {
            case editor = "Editor"
            case viewer = "Viewer"
        }

        public enum State: Sendable, Hashable {
            case none
            case pendingApproval
            case blocked
        }

        public struct IconData: Sendable, Hashable {
            public let initials: String
            public let color: UIColor
            public let image: UIImage?

            public init(
                initials: String,
                color: UIColor,
                image: UIImage?
            ) {
                self.initials = initials
                self.color = color
                self.image = image
            }
        }

        public init(
            handle: String,
            displayName: String,
            role: Role,
            isSelfUser: Bool,
            id: String,
            userType: UserType,
            verificationBadges: [VerificationBadge] = [],
            state: State = .none,
            iconData: IconData? = nil
        ) {
            self.handle = handle
            self.isSelfUser = isSelfUser
            self.displayName = displayName
            self.role = role
            self.id = id
            self.userType = userType
            self.verificationBadges = verificationBadges
            self.state = state
            self.iconData = iconData
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public static func == (lhs: WireDriveParticipant, rhs: WireDriveParticipant) -> Bool {
            lhs.id == rhs.id
        }
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
    static func mocked(selfUserRole: WireDriveConversation.Participant.Role = .editor) -> [Element] {
        [
            .init(
                id: "2b7d1f2c-74bf-4256-a746-8112e006dcd6",
                name: "Conversation 1",
                participants: Set([WireDriveParticipant].mocked(selfUserRole: selfUserRole))
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

public extension Collection<WireDriveParticipant> {
    static func mocked(selfUserRole: WireDriveParticipant.Role = .editor) -> [Element] {
        [
            .init(
                handle: "walterwhite",
                displayName: "Heisenberg",
                role: selfUserRole,
                isSelfUser: true,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [.e2EICertified],
                iconData: .init(initials: "WW", color: .blue, image: nil)
            ),
            .init(
                handle: "jessepinkman",
                displayName: "The Cook",
                role: .viewer,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                verificationBadges: [.e2EICertified, .proteusVerified],
                iconData: .init(initials: "JP", color: .brown, image: nil)
            ),
            .init(
                handle: "tucosalamanca",
                displayName: "Tuco",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                userType: .member,
                iconData: nil
            )
        ]
    }
}
