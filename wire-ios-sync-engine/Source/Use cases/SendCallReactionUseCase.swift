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

import CoreData
import GenericMessageProtocol
import WireDataModel
import WireRequestStrategy

public protocol SendCallReactionUseCaseProtocol {
    func invoke(emoji: String, in conversation: ZMConversation) async throws
}

public struct SendCallReactionUseCase: SendCallReactionUseCaseProtocol, Sendable {

    let messageSender: MessageSenderInterface
    let context: NSManagedObjectContext

    public init(messageSender: MessageSenderInterface, context: NSManagedObjectContext) {
        self.messageSender = messageSender
        self.context = context
    }

    public func invoke(emoji: String, in conversation: ZMConversation) async throws {
        let managedObjectID = conversation.objectID
        let syncConversation = try await context.perform {
            try context.existingObject(with: managedObjectID) as? ZMConversation
        }
        let content = InCallEmoji.with { $0.emojis = [emoji: 1] }
        let entity = GenericMessageEntity(
            message: GenericMessage(content: content),
            context: context,
            conversation: syncConversation,
            completionHandler: nil
        )
        try await messageSender.sendMessage(message: entity)
    }
}
