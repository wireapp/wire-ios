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

public struct WireDriveParticipant: Sendable, Hashable, Identifiable {
    public let handle: String
    public let displayName: String
    public let id: String
    public let isSelfUser: Bool
    public let role: Role
    public let availabilityStatus: AvailabilityStatus
    public let verifications: [Verification]
    public let state: State
    public let iconData: IconData?

    public enum AvailabilityStatus: Sendable, Hashable {
        case none
        case available
        case busy
        case away
    }

    public enum Verification: Sendable, Hashable {
        case e2EICertified
        case proteusVerified
    }

    public enum Role: String, Sendable {
        case editor = "Editor"
        case viewer = "Viewer"
    }

    public enum State: Sendable, Hashable {
        case active
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
        availabilityStatus: AvailabilityStatus = .none,
        verifications: [Verification] = [],
        state: State = .active,
        iconData: IconData? = nil
    ) {
        self.handle = handle
        self.isSelfUser = isSelfUser
        self.displayName = displayName
        self.role = role
        self.id = id
        self.availabilityStatus = availabilityStatus
        self.verifications = verifications
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

public extension Collection<WireDriveParticipant> {
    static func mocked() -> [Element] {
        [
            .init(
                handle: "walterwhite",
                displayName: "Heisenberg",
                role: .editor,
                isSelfUser: false,
                id: UUID().uuidString,
                availabilityStatus: .available,
                verifications: [.e2EICertified],
                iconData: .init(initials: "WW", color: .blue, image: nil)
            ),
            .init(
                handle: "jessepinkman",
                displayName: "The Cook",
                role: .viewer,
                isSelfUser: false,
                id: UUID().uuidString,
                availabilityStatus: .busy,
                verifications: [.e2EICertified, .proteusVerified],
                iconData: .init(initials: "JP", color: .brown, image: nil)
            ),
            .init(
                handle: "tucosalamanca",
                displayName: "Tuco",
                role: .editor,
                isSelfUser: true,
                id: UUID().uuidString,
                iconData: nil
            )
        ]
    }
}
