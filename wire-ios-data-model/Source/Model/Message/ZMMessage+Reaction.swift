//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMMessage {

    static func add(
        reaction: WireProtos.Reaction,
        senderID: UUID,
        conversation: ZMConversation,
        inContext context: NSManagedObjectContext
    ) {
        guard
            let user = ZMUser.fetch(with: senderID, in: context),
            let nonce = UUID(uuidString: reaction.messageID),
            let localMessage = ZMMessage.fetch(withNonce: nonce, for: conversation, in: context)
        else {
            return
        }

        localMessage.setReactions(reaction.toSet(), forUser: user)
        localMessage.updateCategoryCache()
    }

    func selfUserReactions() -> Set<String> {
        let result = usersReaction
            .filter { _, users in users.contains(where: \.isSelfUser) }
            .map { $0.key }

        return Set(result)
    }

}
