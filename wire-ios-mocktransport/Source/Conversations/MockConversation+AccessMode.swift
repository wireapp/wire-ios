//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - MockConversationAccessRole

public enum MockConversationAccessRole: String {
    /// Only the team member can join.
    case team
    /// Only users who have verified their phone number / email can join.
    case activated
    /// Any user can join.
    case nonActivated = "non_activated"

    // MARK: Public

    public static func value(forAllowGuests allowGuests: Bool) -> MockConversationAccessRole {
        allowGuests ? .nonActivated : .team
    }
}

// MARK: - MockConversationAccessRoleV2

public enum MockConversationAccessRoleV2: String {
    /// Users with Wire accounts belonging to the same team owning the conversation.
    case teamMember = "team_member"
    /// Users with Wire accounts belonging to another team or no team.
    case nonTeamMember = "non_team_member"
    /// Users without Wire accounts, or wireless users (i.e users who join with a guest link and temporary account).
    case guest
    /// A service pseudo-user, aka a non-human bot.
    case service

    // MARK: Public

    public static func value(forAllowGuests allowGuests: Bool, forAllowServices allowServices: Bool) -> [String] {
        switch (allowGuests, allowServices) {
        case (true, true):
            [teamMember.rawValue, nonTeamMember.rawValue, guest.rawValue, service.rawValue]
        case (false, false):
            [teamMember.rawValue]
        case (true, false):
            [teamMember.rawValue, nonTeamMember.rawValue, guest.rawValue]
        case (false, true):
            [teamMember.rawValue, service.rawValue]
        }
    }
}

// MARK: - MockConversationAccessMode

public struct MockConversationAccessMode: OptionSet {
    // MARK: Lifecycle

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// Allowed user can be added by an existing conv member.
    public static let invite    = MockConversationAccessMode(rawValue: 1 << 0)
    /// Allowed user can join the conversation using the code.
    public static let code      = MockConversationAccessMode(rawValue: 1 << 1)
    /// Allowed user can join knowing only the conversation ID.
    public static let link      = MockConversationAccessMode(rawValue: 1 << 2)
    /// Internal value that indicates the conversation that cannot be joined (1-1).
    public static let `private` = MockConversationAccessMode(rawValue: 1 << 3)

    public static let legacy    = invite
    public static let teamOnly  = MockConversationAccessMode()
    public static let allowGuests: MockConversationAccessMode = [.invite, .code]

    public let rawValue: Int

    public var stringValue: [String] {
        MockConversationAccessMode.stringValues.compactMap { contains($0) ? $1 : nil }
    }

    public static func value(forAllowGuests allowGuests: Bool) -> MockConversationAccessMode {
        allowGuests ? .allowGuests : .teamOnly
    }

    // MARK: Internal

    static let stringValues: [MockConversationAccessMode: String] = [
        .invite: "invite",
        .code: "code",
        .link: "link",
        .private: "private",
    ]
}

// MARK: Hashable

extension MockConversationAccessMode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
