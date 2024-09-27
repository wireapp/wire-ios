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

public let ZMReactionUnicodeValueKey    = "unicodeValue"
public let ZMReactionMessageValueKey    = "message"
public let ZMReactionUsersValueKey      = "users"

// MARK: - TransportReaction

@objc
public enum TransportReaction: UInt32 {
    case none  = 0
    case heart = 1
    case thumbsUp
    case thumbsDown
    case slightlySmiling
    case beamingFace
    case frowningFace
}

// MARK: - Reaction

@objcMembers
open class Reaction: ZMManagedObject {
    @NSManaged var unicodeValue: String?
    @NSManaged var message: ZMMessage?
    @NSManaged var users: Set<ZMUser>
    @NSManaged private var firstReactionDate: Date?

    public var creationDate: Date {
        firstReactionDate ?? Date.distantPast
    }

    public static func insertReaction(
        _ unicodeValue: String,
        users: [ZMUser],
        inMessage message: ZMMessage,
        creationDate: Date?
    ) -> Reaction {
        let reaction = insertNewObject(in: message.managedObjectContext!)
        reaction.message = message
        reaction.unicodeValue = unicodeValue
        reaction.firstReactionDate = creationDate ?? Date()
        reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).addObjects(from: users)
        return reaction
    }

    override open func keysTrackedForLocalModifications() -> Set<String> {
        [ZMReactionUsersValueKey]
    }

    override open class func entityName() -> String {
        "Reaction"
    }

    override open class func sortKey() -> String? {
        ZMReactionUnicodeValueKey
    }

    public static func validate(unicode: String) -> Bool {
        let isDelete = unicode.count == 0
        let unicodeScalars = unicode.unicodeScalars
        guard let firstScalar = unicodeScalars.first else {
            return false
        }
        let isValidReaction = firstScalar.properties.isEmojiPresentation || firstScalar.properties.isEmoji

        return isDelete || isValidReaction
    }
}
