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
        context.performAndWait {
            for event in events {
                switch event.type {
                case .conversationCreate:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.Conversation>.self) {
                        processor.processPayload(payload, in: context)
                    }

                case .conversationDelete:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self) {
                        processor.processPayload(payload, in: context)
                    }

                case .conversationMemberLeave:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>.self) {
                        processor.processPayload(payload, originalEvent: event, in: context)
                    }

                case .conversationMemberJoin:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>.self) {
                        processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: context
                        )

                        syncConversationForMLSStatus(payload: payload)
                    }

                case .conversationRename:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationName>.self) {
                        processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: context
                        )
                    }

                case .conversationMemberUpdate:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.ConversationMember>.self) {
                        processor.processPayload(
                            payload,
                            in: context
                        )
                    }

                case .conversationAccessModeUpdate:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationAccess>.self) {
                        processor.processPayload(
                            payload,
                            in: context
                        )
                    }

                case .conversationMessageTimerUpdate:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>.self) {
                        processor.processPayload(
                            payload,
                            in: context
                        )
                    }

                case .conversationReceiptModeUpdate:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>.self) {
                        processor.processPayload(
                            payload,
                            in: context
                        )
                    }

                case .conversationConnectRequest:
                    if let payload = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>.self) {
                        processor.processPayload(
                            payload,
                            originalEvent: event,
                            in: context
                        )
                    }

                case .conversationMLSWelcome:
                    guard
                        let data = event.payloadData,
                        let payload = Payload.UpdateConversationMLSWelcome(data)
                    else {
                        break
                    }

                    MLSEventProcessor.shared.process(
                        welcomeMessage: payload.data,
                        in: context
                    )

                default:
                    break
                }
            }
        }
    }

    // MARK: - Member Join

    typealias MemberJoinPayload = Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>

    func fetchOrCreateConversation(id: UUID?, qualifiedID: QualifiedID?, in context: NSManagedObjectContext) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else { return nil }
        return ZMConversation.fetchOrCreate(with: conversationID, domain: qualifiedID?.domain, in: context)
    }

    private func syncConversationForMLSStatus(payload: MemberJoinPayload) {
        // If this is an MLS conversation, we need to fetch some metadata in order to process
        // the welcome message. We expect that all MLS conversations have qualified IDs.
        guard let qualifiedID = payload.qualifiedID else { return }

        syncConversation(qualifiedID: qualifiedID, in: context) {
            guard
                let conversation = self.fetchOrCreateConversation(id: payload.id, qualifiedID: payload.qualifiedID, in: self.context)
            else {
                Logging.eventProcessing.warn("Member join update missing conversation, aborting...")
                return
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

                if users.contains(selfUser) {
                    self.updateMLSStatus(for: conversation, context: self.context)
                }
            }
        }
    }

    private func syncConversation(
        qualifiedID: QualifiedID,
        in context: NSManagedObjectContext,
        then block: @escaping () -> Void
    ) {
        conversationService.syncConversation(qualifiedID: qualifiedID) {
            context.performAndWait {
                block()
            }
        }
    }

    private func updateMLSStatus(for conversation: ZMConversation, context: NSManagedObjectContext) {
        MLSEventProcessor.shared.updateConversationIfNeeded(
            conversation: conversation,
            groupID: nil,
            context: context
        )
    }

}
