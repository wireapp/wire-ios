//
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

/// Defines how users can join a conversation.
public struct ConversationAccessMode: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    /// Allowed user can be added by an existing conv member.
    public static let invite    = ConversationAccessMode(rawValue: 1 << 0)
    /// Allowed user can join the conversation using the code.
    public static let code      = ConversationAccessMode(rawValue: 1 << 1)
    /// Allowed user can join knowing only the conversation ID.
    public static let link      = ConversationAccessMode(rawValue: 1 << 2)
    /// Internal value that indicates the conversation that cannot be joined (1-1).
    public static let `private` = ConversationAccessMode(rawValue: 1 << 3)

    public static let legacy    = invite
    public static let teamOnly  = ConversationAccessMode()
    public static let allowGuests: ConversationAccessMode = [.invite, .code]
}

extension ConversationAccessMode: Hashable {
    public var hashValue: Int {
        return self.rawValue
    }
}

public extension ConversationAccessMode {
    internal static let stringValues: [ConversationAccessMode: String] = [.invite: "invite",
                                                                          .code: "code",
                                                                          .link: "link",
                                                                          .`private`: "private"]

    var stringValue: [String] {
        return ConversationAccessMode.stringValues.compactMap { self.contains($0) ? $1 : nil }
    }

    init(values: [String]) {
        var result = ConversationAccessMode()
        ConversationAccessMode.stringValues.forEach {
            if values.contains($1) {
                result.formUnion($0)
            }
        }
        self = result
    }
}

public extension ConversationAccessMode {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessMode {
        return allowGuests ? .allowGuests : .teamOnly
    }
}

/// Defines who can join the conversation.
public enum ConversationAccessRole: String {
    /// Only the team member can join.
    case team = "team"
    /// Only users who have verified their phone number / email can join.
    case activated = "activated"
    /// Any user can join.
    case nonActivated = "non_activated"
}

public extension ConversationAccessRole {
    static func value(forAllowGuests allowGuests: Bool) -> ConversationAccessRole {
        return allowGuests ? ConversationAccessRole.nonActivated : ConversationAccessRole.team
    }
}

extension ZMConversation: SwiftConversationLike {
    @NSManaged dynamic internal var accessModeStrings: [String]?
    @NSManaged dynamic internal var accessRoleString: String?

    public var sortedActiveParticipantsUserTypes: [UserType] {
        return sortedActiveParticipants
    }

    public var teamType: TeamType? {
        return team
    }

    /// If set to false, only team member can join the conversation.
    /// True means that a regular guest OR wireless guests could join
    /// Controls the values of `accessMode` and `accessRole`.
    @objc public var allowGuests: Bool {
        get {
            return accessMode != .teamOnly && accessRole != .team
        }
        set {
            accessMode = ConversationAccessMode.value(forAllowGuests: newValue)
            accessRole = ConversationAccessRole.value(forAllowGuests: newValue)
        }
    }

    // The conversation access mode is stored as an array of string in CoreData, cf. `acccessModeStrings`.

    /// Defines how users can join a conversation.
    public var accessMode: ConversationAccessMode? {
        get {
            guard let strings = self.accessModeStrings else {
                return nil
            }

            return ConversationAccessMode(values: strings)
        }
        set {
            guard let value = newValue else {
                accessModeStrings = nil
                return
            }
            accessModeStrings = value.stringValue
        }
    }

    /// Defines who can join the conversation.
    public var accessRole: ConversationAccessRole? {
        get {
            guard let strings = self.accessRoleString else {
                return nil
            }

            return ConversationAccessRole(rawValue: strings)
        }
        set {
            guard let value = newValue else {
                accessRoleString = nil
                return
            }
            accessRoleString = value.rawValue
        }
    }
}
