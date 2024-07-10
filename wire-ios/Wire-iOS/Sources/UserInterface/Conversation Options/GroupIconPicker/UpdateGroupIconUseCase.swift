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

import WireAPI
import WireDataModel

public struct UpdateGroupIconUseCase {

    let conversationId: WireDataModel.QualifiedID
    let context: NSManagedObjectContext
    let api: WireAPI.ConversationsAPI

    init(api: WireAPI.ConversationsAPI, conversationId: WireDataModel.QualifiedID, context: NSManagedObjectContext) {
        self.conversationId = conversationId
        self.context = context
        self.api = api
    }

    public func invoke(colorString: String?, emoji: String?) async throws {
        guard colorString != nil || emoji != nil else {
            debugPrint("nothing to update")
            return
        }
        let id = conversationId.toWireAPIQualifiedId()
//        try await api.updateGroupIcon(for: id, hexColor: colorString, emoji: emoji)

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

private extension WireDataModel.QualifiedID {
    func toWireAPIQualifiedId() -> WireAPI.QualifiedID {
        .init(uuid: self.uuid, domain: self.domain)
    }
}
