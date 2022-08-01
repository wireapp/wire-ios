// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel

public class ConversationEventProcessor: NSObject, ConversationEventProcessorProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    // MARK: - Methods

    public func processConversationEvents(_ events: [ZMUpdateEvent]) {
        context.performAndWait {
            for event in events {
                switch event.type {
                case .conversationCreate:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.Conversation>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationDelete:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationMemberLeave:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationMemberJoin:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationRename:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationName>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationMemberUpdate:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.ConversationMember>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationAccessModeUpdate:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationAccess>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationMessageTimerUpdate:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationReceiptModeUpdate:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationConnectRequest:
                    let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>.self)
                    conversationEvent?.process(in: context, originalEvent: event)

                case .conversationMLSWelcome:
                    guard let data = event.payloadData else { break }
                    let conversationEvent = Payload.UpdateConversationMLSWelcome(data)
                    conversationEvent?.process(in: context, originalEvent: event)

                default:
                    break
                }
            }
        }
    }

}
