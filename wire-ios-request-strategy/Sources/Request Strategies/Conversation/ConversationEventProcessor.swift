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
    let conversationService: ConversationServiceProtocol

    // MARK: - Life cycle

    public convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            conversationService: ConversationService(context: context)
        )
    }

    public init(
        context: NSManagedObjectContext,
        conversationService: ConversationServiceProtocol
    ) {
        self.context = context
        self.conversationService = conversationService
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
                    if let conversationEvent = event.eventPayload(type: Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>.self) {
                        processMemberJoin(payload: conversationEvent, originalEvent: event)
                    }

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

    // MARK: - Member Join

    typealias MemberJoinPayload = Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>

    func processMemberJoin(payload: MemberJoinPayload, originalEvent: ZMUpdateEvent) {
        syncConversationIfNeeded(qualifiedID: payload.qualifiedID, in: context) {
            guard
                let conversation = self.fetchOrCreateConversation(id: payload.id, qualifiedID: payload.qualifiedID, in: self.context)
            else {
                Logging.eventProcessing.warn("Member join update missing conversation, aborting...")
                return
            }

            if let usersAndRoles = payload.data.users?.map({ $0.fetchUserAndRole(in: self.context, conversation: conversation)! }) {
                let selfUser = ZMUser.selfUser(in: self.context)
                let users = Set(usersAndRoles.map { $0.0 })
                let newUsers = !users.subtracting(conversation.localParticipants).isEmpty

                if users.contains(selfUser) || newUsers {
                    // TODO jacob refactor to append method on conversation
                    _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: self.context)
                }

                if users.contains(selfUser) {
                    self.updateMLSStatus(for: conversation, context: self.context)
                }

                conversation.addParticipantsAndUpdateConversationState(usersAndRoles: usersAndRoles)
            } else if let users = payload.data.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: self.context)}) {
                // NOTE: legacy code path for backwards compatibility with servers without role support
                let users = Set(users)
                let selfUser = ZMUser.selfUser(in: self.context)

                if !users.isSubset(of: conversation.localParticipantsExcludingSelf) || users.contains(selfUser) {
                    // TODO jacob refactor to append method on conversation
                    _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: self.context)
                }
                conversation.addParticipantsAndUpdateConversationState(users: users, role: nil)
            }
        }
    }

    func fetchOrCreateConversation(id: UUID?, qualifiedID: QualifiedID?, in context: NSManagedObjectContext) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else { return nil }
        return ZMConversation.fetchOrCreate(with: conversationID, domain: qualifiedID?.domain, in: context)
    }

    private func syncConversationIfNeeded(
        qualifiedID: QualifiedID?,
        in context: NSManagedObjectContext,
        then block: @escaping () -> Void
    ) {
        // If this is an MLS conversation, we need to fetch some metadata in order to process
        // the welcome message. We expect that all MLS conversations have qualified IDs.
        if let qualifiedID = qualifiedID {
            conversationService.syncConversation(qualifiedID: qualifiedID) {
                context.performAndWait {
                    block()
                }
            }

        } else {
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

public protocol ConversationServiceProtocol {

    func syncConversation(
        qualifiedID: QualifiedID,
        completion: @escaping () -> Void
    )

}
