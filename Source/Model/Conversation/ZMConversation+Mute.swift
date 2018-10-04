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

/// Defines what kind of messages are muted.
public struct MutedMessageTypes: OptionSet {
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /// None of the messages are muted.
    public static let none     = MutedMessageTypes(rawValue: 0)

    /// All messages, including mentions, are muted.
    public static let all: MutedMessageTypes = [.nonMentions, .mentions]
    
    /// Only non-mentions are muted.
    public static let nonMentions = MutedMessageTypes(rawValue: 1 << 0)
    private static let mentions = MutedMessageTypes(rawValue: 1 << 1)
}

public extension ZMConversation {
    @NSManaged @objc public var mutedStatus: Int32
    
    public var mutedMessageTypes: MutedMessageTypes {
        get {
            return MutedMessageTypes(rawValue: mutedStatus)
        }
        set {
            mutedStatus = newValue.rawValue
            
            if let moc = managedObjectContext,
                moc.zm_isUserInterfaceContext,
                let lastServerTimestamp = self.lastServerTimeStamp {
                updateMuted(lastServerTimestamp, synchronize: true)
            }
        }
    }
}
