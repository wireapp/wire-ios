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


extension ZMConversation {
    @objc(normalizeText:forMentions:)
    func normalize(text: String, for mentions: [ZMMention]) -> String {

        guard ZMUser.servicesMustBeMentioned else {
            return text
        }
        
        // If the message is for a bot, remove the mention handle

        guard let firstMention = mentions.first else {
            return text
        }

        guard let firstMentionedUser = (self.lastServerSyncedActiveParticipants.set as! Set<ZMUser>)
            .first(where: { $0.remoteIdentifier!.transportString() == firstMention.userId }) else {
                return text
        }

        guard firstMentionedUser.isServiceUser else {
            return text
        }

        // Remove the ZMUser.serviceMentionKeyword (while it's here)

        guard let mentionHandleRange = text.range(of: ZMUser.serviceMentionKeyword + " ") else {
            return text
        }

        return String(text[mentionHandleRange.upperBound...])

    }

    @objc(mentionsInText:)
    func mentions(in text: String) -> [ZMMention] {
        let serviceUsers = (self.lastServerSyncedActiveParticipants.set as! Set<ZMUser>).serviceUsers
        var mentionedUsers: [ZMUser] = []

        if text.starts(with: ZMUser.serviceMentionKeyword + " ") {
            mentionedUsers.append(contentsOf: serviceUsers)
        }

        return ZMMentionBuilder.build(mentionedUsers)
    }

}
