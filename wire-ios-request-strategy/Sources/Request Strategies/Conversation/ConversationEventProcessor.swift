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

public class ConversationEventProcessor: NSObject, ConversationEventProcessorProtocol, ZMEventAsyncConsumer {

    // MARK: - Properties

    let context: NSManagedObjectContext
    let conversationService: ConversationServiceInterface
    private let processor = ConversationEventPayloadProcessor()

    // MARK: - Life cycle

    public convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            conversationService: ConversationService(context: context)
        )
    }

    public init(
        context: NSManagedObjectContext,
        conversationService: ConversationServiceInterface
    ) {
        self.context = context
        self.conversationService = conversationService
        super.init()
    }

    // MARK: - Methods

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) async {
        await processConversationEvents(events)
    }

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {

        for event in events {
            switch event.type {
            case .conversationCreate:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.Conversation>.self) {
                    await context.perform { self.processor.processPayload(payload, in: self.context) }
                }

            case .conversationDelete:

                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self) {
                    await context.perform { self.processor.processPayload(payload, in: self.context) }
                }

            case .conversationMemberLeave:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>.self) {
                    await context.perform { self.processor.processPayload(payload, originalEvent: event, in: self.context) }
                }

            case .conversationMemberJoin:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: self.context
                        )
                    }
                    await syncConversationForMLSStatus(payload: payload)
                }

            case .conversationRename:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationName>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: self.context
                        )
                    }
                }

            case .conversationMemberUpdate:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.ConversationMember>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            in: self.context
                        )
                    }
                }

            case .conversationAccessModeUpdate:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationAccess>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            in: self.context
                        )
                    }
                }

            case .conversationMessageTimerUpdate:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            in: self.context
                        )
                    }
                }

            case .conversationReceiptModeUpdate:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            in: self.context
                        )
                    }
                }

            case .conversationConnectRequest:
                if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>.self) {
                    await context.perform {
                        self.processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: self.context
                        )
                    }
                }

            case .conversationMLSWelcome:
                guard
                    let data = event.payloadData,
                    let payload = Payload.UpdateConversationMLSWelcome(data)
                else {
                    break
                }
                // TODO: this will become async as MLSService conversationExists will become async
                MLSEventProcessor.shared.process(
                    welcomeMessage: payload.data,
                    in: self.context
                )

            default:
                break
            }
        }
    }

    // MARK: - Member Join

    typealias MemberJoinPayload = Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>

    func fetchOrCreateConversation(id: UUID?, qualifiedID: QualifiedID?, in context: NSManagedObjectContext) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else { return nil }
        return ZMConversation.fetchOrCreate(with: conversationID, domain: qualifiedID?.domain, in: context)
    }

    private func syncConversationForMLSStatus(payload: MemberJoinPayload) async {
        // If this is an MLS conversation, we need to fetch some metadata in order to process
        // the welcome message. We expect that all MLS conversations have qualified IDs.
        guard let qualifiedID = payload.qualifiedID else { return }

        await conversationService.syncConversation(qualifiedID: qualifiedID)

        var usersContainedSelfUser = false

        let conversation: ZMConversation? = await self.context.perform {
            guard
                let conversation = self.fetchOrCreateConversation(id: payload.id, qualifiedID: payload.qualifiedID, in: self.context)
            else {
                Logging.eventProcessing.warn("Member join update missing conversation, aborting...")
                return nil
            }

            if let usersAndRoles = payload.data.users?.map({
                self.processor.fetchUserAndRole(
                    from: $0,
                    for: conversation,
                    in: self.context
                )!
            }) {
                let selfUser = ZMUser.selfUser(in: self.context)
                let users = Set(usersAndRoles.map { $0.0 })
                usersContainedSelfUser = users.contains(selfUser)
            }
            return conversation
        }

        if let conversation, usersContainedSelfUser {
            await self.updateMLSStatus(for: conversation, context: self.context)
        }

    }

    private func updateMLSStatus(for conversation: ZMConversation, context: NSManagedObjectContext) async {
        MLSEventProcessor.shared.updateConversationIfNeeded(
            conversation: conversation,
            groupID: nil,
            context: context
        )
    }

}
