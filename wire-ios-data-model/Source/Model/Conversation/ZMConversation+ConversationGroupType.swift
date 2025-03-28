//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@objc
public enum ConversationGroupType: Int {

    /// A group conversation

    case group = 0

    /// A channel conversation

    case channel = 1

}

extension ZMConversation: HasConversationGroupType {

    /// The underlying group conversation type string value.

    @NSManaged private var groupTypeValue: NSNumber?

    /// The group conversation type.
    ///
    /// - note: `nil` if the conversation is not a group conversation. Defaults to `.group` if not set.

    public var groupType: ConversationGroupType? {
        get {
            guard conversationType == .group else { return nil }

            // Default to `group` type if not set.
            guard let value = groupTypeValue?.intValue else { return .group }

            return ConversationGroupType(rawValue: value)
        }
        set {
            groupTypeValue = newValue.map { NSNumber(value: $0.rawValue) }
        }
    }

}

public protocol HasConversationGroupType {

    var groupType: ConversationGroupType? { get }

}
