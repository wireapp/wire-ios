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
import WireDataModel

public class ConversationEventProcessor: NSObject, ConversationEventProcessorProtocol, ZMEventAsyncConsumer {

    // MARK: - Properties

    let context: NSManagedObjectContext
    let conversationService: ConversationServiceInterface
    let mlsEventProcessor: MLSEventProcessing

    private lazy var processor = ConversationEventPayloadProcessor(
        mlsEventProcessor: mlsEventProcessor,
        removeLocalConversation: RemoveLocalConversationUseCase()
    )
    private let eventPayloadDecoder = EventPayloadDecoder()

    // MARK: - Life cycle

    public convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            conversationService: ConversationService(context: context),
            mlsEventProcessor: MLSEventProcessor(context: context)
        )
    }

    public init(
        context: NSManagedObjectContext,
        conversationService: ConversationServiceInterface,
        mlsEventProcessor: MLSEventProcessing
    ) {
        self.context = context
        self.conversationService = conversationService
        self.mlsEventProcessor = mlsEventProcessor
        super.init()
    }

    // MARK: - Methods

    public func processPayload(_ payload: ZMTransportData) {
        if let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
            Task {
                await processConversationEvents([event])
            }
        }
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) async {
        await processConversationEvents(events)
    }

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {
        for event in events {
            await processConversationEvent(event)
        }
    }

    private func processConversationEvent(_ event: ZMUpdateEvent) async {
        switch event.type {
        case .conversationCreate:
            await processConversationCreate(event)

        case .conversationDelete:
            await processConversationDelete(event)

        case .conversationMemberLeave:
            await processConversationMemberLeave(event)

        case .conversationMemberJoin:
            await processConversationMemberJoin(event)

        case .conversationRename:
            await processConversationRename(event)

        case .conversationMemberUpdate:
            await processConversationMemberUpdate(event)

        case .conversationAccessModeUpdate:
            await processConversationAccessModeUpdate(event)

        case .conversationMessageTimerUpdate:
            await processConversationMessageTimerUpdate(event)

        case .conversationReceiptModeUpdate:
            await processConversationReceiptModeUpdate(event)

        case .conversationConnectRequest:
            await processConversationConnectRequest(event)

        case .conversationMLSWelcome:
            await processConversationMLSWelcome(event)

        case .conversationProtocolUpdate:
            await processConversationProtocolChange(event)

        default:
            break
        }
    }

    private func processConversationCreate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.Conversation>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(payload, in: context)
    }

    private func processConversationDelete(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(payload, in: context)
    }

    private func processConversationMemberLeave(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(payload, originalEvent: event, in: context)
    }

    private func processConversationMemberJoin(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                originalEvent: event,
                in: self.context
            )
        }
        await syncConversationForMLSStatus(payload: payload)
    }

    private func processConversationRename(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationName>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                originalEvent: event,
                in: self.context
            )
        }
    }

    private func processConversationMemberUpdate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.ConversationMember>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                in: self.context
            )
        }
    }

    private func processConversationAccessModeUpdate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationAccess>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                in: self.context
            )
        }
    }

    private func processConversationMessageTimerUpdate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                in: self.context
            )
        }
    }

    private func processConversationReceiptModeUpdate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                in: self.context
            )
        }
    }

    private func processConversationConnectRequest(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>.self,
            from: event.payload
        ) else { return }

        await context.perform {
            self.processor.processPayload(
                payload,
                originalEvent: event,
                in: self.context
            )
        }
    }

    private func processConversationMLSWelcome(_ event: ZMUpdateEvent) async {
        guard
            let payload = try? eventPayloadDecoder.decode(
                Payload.UpdateConversationMLSWelcome.self,
                from: event.payload
            ),
            let qualifiedID = payload.qualifiedID ?? BackendInfo.domain.map({
                QualifiedID(uuid: payload.id, domain: $0)
            })
        else { return }

        await mlsEventProcessor.process(
            welcomeMessage: payload.data,
            conversationID: qualifiedID,
            in: context
        )
    }

    private func processConversationProtocolChange(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationProtocolChange>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(
            payload,
            originalEvent: event,
            in: context
        )
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
            await updateMLSStatus(for: conversation, context: context)
        }

    }

    private func updateMLSStatus(for conversation: ZMConversation, context: NSManagedObjectContext) async {
        await mlsEventProcessor.updateConversationIfNeeded(
            conversation: conversation,
            groupID: nil,
            context: context
        )
    }

}
