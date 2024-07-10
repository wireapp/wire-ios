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

import WireDataModel

struct UpdateGroupIconUseCase {

    var conversationId: QualifiedID
    var context: NSManagedObjectContext

    func invoke(colorString: String?, emoji: String?) async {
        guard colorString != nil || emoji != nil else {
            debugPrint("nothing to update")
            return
        }
        debugPrint("send \(colorString) to the backend!")
        // TODO: do the request here
        await saveConversation(colorString: colorString, emoji: emoji)
    }

    private func saveConversation(colorString: String?, emoji: String?) async {
        await context.perform {
            let conversation = ZMConversation.fetchOrCreate(with: conversationId.uuid, domain: conversationId.domain, in: context)
            conversation.groupColor = colorString
            conversation.groupEmoji = emoji
            context.saveOrRollback()
        }
    }
}
