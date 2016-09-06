//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public let ZMReactionUnicodeValueKey    = "unicodeValue"
public let ZMReactionMessageValueKey    = "message"
public let ZMReactionUsersValueKey      = "users"


@objc public enum TransportReaction : UInt32 {
    case None  = 0
    case Heart = 1
}


@objc(Reaction)
public class Reaction : ZMManagedObject {
    
    @NSManaged var unicodeValue : String?
    @NSManaged var message      : ZMMessage?
    @NSManaged var users        : Set<ZMUser>
    
    
    public static func insertReaction(unicodeValue: String, users: [ZMUser], inMessage message: ZMMessage) -> Reaction
    {
        let reaction = self.insertNewObjectInManagedObjectContext(message.managedObjectContext)
        reaction.message = message
        reaction.unicodeValue = unicodeValue
        reaction.mutableSetValueForKey(ZMReactionUsersValueKey).addObjectsFromArray(users)
        return reaction
    }
    
    
    public override func keysTrackedForLocalModifications() -> [AnyObject]! {
        return [ZMReactionUsersValueKey]
    }
    public override static func entityName() -> String! {
        return "Reaction"
    }
    
    public override static func sortKey() -> String! {
        return ZMReactionUnicodeValueKey
    }
    
    @objc public static func transportReaction(fromUnicode: String) -> TransportReaction {
        switch fromUnicode {
        case "❤️":
            return .Heart
        default:
            return .None
        }

    }
    
}
