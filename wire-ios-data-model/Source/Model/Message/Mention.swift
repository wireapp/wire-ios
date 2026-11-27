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
import GenericMessageProtocol

@objc
public class Mention: NSObject {

    public let range: NSRange
    public let user: UserType?
    public let isEveryone: Bool

    init?(_ protobuf: GenericMessageProtocol.Mention, context: NSManagedObjectContext) {
        let userRemoteID = protobuf.hasQualifiedUserID ? protobuf.qualifiedUserID.id : protobuf.userID
        let domain = protobuf.hasQualifiedUserID ? protobuf.qualifiedUserID.domain : nil

        guard protobuf.length > 0, protobuf.start >= 0 else { return nil }
        if protobuf.everyone {
            self.user = nil
            self.isEveryone = true
        } else {
            guard let userId = UUID(uuidString: userRemoteID),
                  let user = ZMUser.fetch(with: userId, domain: domain, in: context) else { return nil }
            self.user = user
            self.isEveryone = false
        }
        self.range = NSRange(location: Int(protobuf.start), length: Int(protobuf.length))
    }

    public init(range: NSRange, user: UserType) {
        self.range = range
        self.user = user
        self.isEveryone = false
    }

    public init(range: NSRange, isEveryone: Bool) {
        self.range = range
        self.user = nil
        self.isEveryone = isEveryone
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherMention = object as? Mention else { return false }

        return isEveryone == otherMention.isEveryone &&
            (isEveryone || user?.isEqual(otherMention.user) == true) && NSEqualRanges(range, otherMention.range)
    }

}

extension Mention {
    static func mentions(
        from protos: [GenericMessageProtocol.Mention]?,
        messageText: String?,
        moc: NSManagedObjectContext?
    ) -> [Mention] {
        guard let protos,
              let messageText,
              let managedObjectContext = moc else { return [] }

        let mentions = Array(protos.compactMap { Mention($0, context: managedObjectContext) }.prefix(500))
        var mentionRanges = IndexSet()
        let messageRange = NSRange(messageText.startIndex ..< messageText.endIndex, in: messageText)

        return mentions.filter { mention  in
            let range = mention.range.range

            guard !mentionRanges.intersects(integersIn: range),
                  range.upperBound <= messageRange.upperBound else { return false }

            mentionRanges.insert(integersIn: range)

            return true
        }
    }
}

// MARK: - Helper

private extension NSRange {
    var range: Range<Int> {
        lowerBound ..< upperBound
    }
}

@objc
public extension Mention {
    var isForSelf: Bool {
        isEveryone || user?.isSelfUser == true
    }
}

public extension TextMessageData {
    var isMentioningSelf: Bool {
        mentions.any(\.isForSelf)
    }
}
