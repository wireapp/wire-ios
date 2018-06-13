////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public enum MockConversationAccessRole: String {
    /// Only the team member can join.
    case team = "team"
    /// Only users who have verified their phone number / email can join.
    case activated = "activated"
    /// Any user can join.
    case nonActivated = "non_activated"

    public static func value(forAllowGuests allowGuests: Bool) -> MockConversationAccessRole {
        return allowGuests ? .nonActivated : .team
    }
}

public struct MockConversationAccessMode: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
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

    internal static let stringValues: [MockConversationAccessMode: String] = [.invite: "invite",
                                                                              .code: "code",
                                                                              .link: "link",
                                                                              .`private`: "private"]

    public var stringValue: [String] {
        return MockConversationAccessMode.stringValues.compactMap { self.contains($0) ? $1 : nil }
    }


    public static func value(forAllowGuests allowGuests: Bool) -> MockConversationAccessMode {
        return allowGuests ? .allowGuests : .teamOnly
    }
}

extension MockConversationAccessMode: Hashable {
    public var hashValue: Int {
        return self.rawValue
    }
}
