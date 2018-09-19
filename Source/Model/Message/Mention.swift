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

@objc
public class Mention: NSObject {
    
    public let range: NSRange
    public let user: UserType
    
    init?(_ protobuf: ZMMention, context: NSManagedObjectContext) {
        guard protobuf.hasUserId(), let userId = UUID(uuidString: protobuf.userId),
              protobuf.length > 0, protobuf.start >= 0,
              let user = ZMUser(remoteID: userId, createIfNeeded: false, in: context) else { return nil }
        
        self.user = user
        self.range = NSRange(location: Int(protobuf.start), length: Int(protobuf.length))
    }
    
    public init(range: NSRange, user: UserType) {
        self.range = range
        self.user = user
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherMention = object as? Mention else { return false }
        
        return user.isEqual(otherMention.user) && NSEqualRanges(range, otherMention.range)
    }
        
}

// MARK: - Helper

@objc public extension Mention {
    var isForSelf: Bool {
        return user.isSelfUser
    }
}

public extension ZMTextMessageData {
    var isMentioningSelf: Bool {
        return mentions.any(\.isForSelf)
    }
}
