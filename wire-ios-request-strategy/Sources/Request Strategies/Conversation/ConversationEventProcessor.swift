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

import Foundation
import WireDataModel
import WireLogging

public class ConversationEventProcessor: NSObject, LegacyConversationEventProcessorProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext
    let conversationService: ConversationServiceInterface
    let mlsEventProcessor: MLSEventProcessing

    private lazy var processor = ConversationEventPayloadProcessor(
        mlsEventProcessor: mlsEventProcessor,
        removeLocalConversation: RemoveLocalConversationUseCase(),
        isFederationEnabled: isFederationEnabled
    )
    private let eventPayloadDecoder = EventPayloadDecoder()
    private let localDomain: String?
    private let isFederationEnabled: Bool

    // MARK: - Life cycle

    public convenience init(
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.init(
            context: context,
            conversationService: ConversationService(context: context, localDomain: localDomain),
            mlsEventProcessor: MLSEventProcessor(context: context, localDomain: localDomain),
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
    }

    public init(
        context: NSManagedObjectContext,
        conversationService: ConversationServiceInterface,
        mlsEventProcessor: MLSEventProcessing,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.conversationService = conversationService
        self.mlsEventProcessor = mlsEventProcessor
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        super.init()
    }

    // MARK: - Methods

    /// Process Conversation Rename event
    /// - Parameter payload: payload containing the event
    /// - Note: This method needs to be synchronous because it's used by a request Strategy
    /// This can be removed once ConversationRequestStrategy is removed
    func processConversationRenamePayload(_ payload: ZMTransportData) {
        // here's no uuid is needed since we process it directly it's just convenience to get the payload
        if let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
            do {
                let payload = try eventPayloadDecoder.decode(
                    Payload.ConversationEvent<Payload.UpdateConversationName>.self,
                    from: event.payload
                )

                processor.processPayload(
                    payload,
                    originalEvent: event,
                    in: context
                )
            } catch {
                WireLogger.eventProcessing
                    .error("error processing UpdateConversationName: \(error.localizedDescription)")
            }
        }
    }

    /// This method is called from EventProcessor directly
    public func processEvents(_ events: [ZMUpdateEvent]) async {
        await processConversationEvents(events)
    }

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {
        for event in events {
            await processConversationEvent(event)
        }
    }

    public func processAndSaveConversationEvents(_ events: [ZMUpdateEvent]) async {
        await processConversationEvents(events)
        _ = await context.perform { [weak self] in
            self?.context.saveOrRollback()
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

        case .conversationAddPermissionUpdate:

            await processConversationAddPermissionUpdate(event: event)

        // TODO: [WPB-18464] - process new event when backend ready, processor will properly map the duration to a localized string and create the ZMSystemMessage
//        case let .channelHistoryDepthModified(event):
//            await processConversationChannelHistoryDepthModified(event: event)
        default:
            break
        }
    }

//    private func processConversationChannelHistoryDepthModified(event: ZMUpdateEvent) {
//        guard let payload = try? eventPayloadDecoder.decode(
//            Payload.ConversationEvent<Payload.ChannelHistoryDepthModified>.self,
//            from: event.payload
//        ) else { return }
//
//        await processor.processPayload(payload, in: context)
//    }

    private func processConversationAddPermissionUpdate(event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationPermission>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(payload, in: context)
    }

    private func processConversationCreate(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.CreatedConversation>.self,
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
            Payload.ConversationEvent<Payload.UpdateConversationMemberLeave>.self,
            from: event.payload
        ) else { return }

        await processor.processPayload(payload, originalEvent: event, in: context)
    }

    private func processConversationMemberJoin(_ event: ZMUpdateEvent) async {
        guard let payload = try? eventPayloadDecoder.decode(
            Payload.ConversationEvent<Payload.UpdateConversationMemberJoin>.self,
            from: event.payload
        ) else { return }

        if let conversationID = payload.qualifiedID {
            await conversationService.syncConversationIfMissing(qualifiedID: conversationID)
        }
        await context.perform {
            self.processor.processPayload(
                payload,
                originalEvent: event,
                in: self.context
            )
        }
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
            let qualifiedID = payload.qualifiedID ?? localDomain.map({
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

    typealias MemberJoinPayload = Payload.ConversationEvent<Payload.UpdateConversationMemberJoin>

    func fetchOrCreateConversation(
        id: UUID?,
        qualifiedID: QualifiedID?,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else { return nil }
        return ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: qualifiedID?.domain,
            in: context
        )
    }
}
