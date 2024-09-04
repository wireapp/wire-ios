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

import CoreData
import Foundation
import WireAPI

protocol CategorizedEventProcessorBuilder {
    func makeCategorizedEventProcessor(
        for updateEvent: UpdateEvent,
        context: NSManagedObjectContext
    ) throws -> any CategorizedEventProcessorProtocol
}

protocol ConversationEventProcessorBuilder {
    func makeConversationProcessor(
        for conversationEvent: ConversationEvent,
        context: NSManagedObjectContext
    ) -> any ConversationEventProcessorProtocol
}

protocol FeatureConfigEventProcessorBuilder {
    func makeFeatureConfigProcessor(
        for featureConfigEvent: FeatureConfigEvent,
        context: NSManagedObjectContext
    ) -> any FeatureConfigEventProcessorProtocol
}

protocol FederationEventProcessorBuilder {
    func makeFederationProcessor(
        for federationEvent: FederationEvent,
        context: NSManagedObjectContext
    ) -> any FederationEventProcessorProtocol
}

protocol UserEventProcessorBuilder {
    func makeUserProcessor(
        for userEvent: UserEvent,
        context: NSManagedObjectContext
    ) -> any UserEventProcessorProtocol
}

protocol TeamEventProcessorBuilder {
    func makeTeamProcessor(
        for teamEvent: TeamEvent,
        context: NSManagedObjectContext
    ) -> any TeamEventProcessorProtocol
}

typealias EventBuilderProtocol = CategorizedEventProcessorBuilder & ConversationEventProcessorBuilder & FeatureConfigEventProcessorBuilder & FederationEventProcessorBuilder & TeamEventProcessorBuilder & UserEventProcessorBuilder

struct EventProcessorBuilder: EventBuilderProtocol {

    enum Error: Swift.Error {
        case unknownEvent(String)
    }

    // MARK: - Categorized top-level processors

    func makeCategorizedEventProcessor(
        for updateEvent: UpdateEvent,
        context: NSManagedObjectContext
    ) throws -> any CategorizedEventProcessorProtocol {
        switch updateEvent {
        case .conversation(let conversationEvent):
            ConversationEventProcessor(
                event: conversationEvent,
                context: context
            )

        case .featureConfig(let featureConfigEvent):
            FeatureConfigEventProcessor(
                event: featureConfigEvent,
                context: context
            )

        case .federation(let federationEvent):
            FederationEventProcessor(
                event: federationEvent,
                context: context
            )

        case .user(let userEvent):
            UserEventProcessor(
                event: userEvent,
                context: context
            )

        case .team(let teamEvent):
            TeamEventProcessor(
                event: teamEvent,
                context: context
            )

        case .unknown(let eventType):
            throw Error.unknownEvent(eventType)
        }
    }

    // MARK: - Conversation processors

    func makeConversationProcessor(
        for conversationEvent: ConversationEvent,
        context: NSManagedObjectContext
    ) -> any ConversationEventProcessorProtocol {
        switch conversationEvent {
        case .accessUpdate(let event):
            ConversationAccessUpdateEventProcessor(
                event: event,
                context: context
            )

        case .codeUpdate(let event):
            ConversationCodeUpdateEventProcessor(
                event: event,
                context: context
            )

        case .create(let event):
            ConversationCreateEventProcessor(
                event: event,
                context: context
            )

        case .delete(let event):
            ConversationDeleteEventProcessor(
                event: event,
                context: context
            )

        case .memberJoin(let event):
            ConversationMemberJoinEventProcessor(
                event: event,
                context: context
            )

        case .memberLeave(let event):
            ConversationMemberLeaveEventProcessor(
                event: event,
                context: context
            )

        case .memberUpdate(let event):
            ConversationMemberUpdateEventProcessor(
                event: event,
                context: context
            )

        case .messageTimerUpdate(let event):
            ConversationMessageTimerUpdateEventProcessor(
                event: event,
                context: context
            )

        case .mlsMessageAdd(let event):
            ConversationMLSMessageAddEventProcessor(
                event: event,
                context: context
            )

        case .mlsWelcome(let event):
            ConversationMLSWelcomeEventProcessor(
                event: event,
                context: context
            )

        case .proteusMessageAdd(let event):
            ConversationProteusMessageAddEventProcessor(
                event: event,
                context: context
            )

        case .protocolUpdate(let event):
            ConversationProtocolUpdateEventProcessor(
                event: event,
                context: context
            )

        case .receiptModeUpdate(let event):
            ConversationReceiptModeUpdateEventProcessor(
                event: event,
                context: context
            )

        case .rename(let event):
            ConversationRenameEventProcessor(
                event: event,
                context: context
            )

        case .typing(let event):
            ConversationTypingEventProcessor(
                event: event,
                context: context
            )
        }
    }

    // MARK: - Feature config processors

    func makeFeatureConfigProcessor(
        for featureConfigEvent: FeatureConfigEvent,
        context: NSManagedObjectContext
    ) -> any FeatureConfigEventProcessorProtocol {
        switch featureConfigEvent {
        case .update(let event):
            FeatureConfigUpdateEventProcessor(
                event: event,
                context: context
            )
        }
    }

    // MARK: - Federation processors

    func makeFederationProcessor(
        for federationEvent: FederationEvent,
        context: NSManagedObjectContext
    ) -> any FederationEventProcessorProtocol {
        switch federationEvent {
        case .connectionRemoved(let federationConnectionRemovedEvent):
            FederationConnectionRemovedEventProcessor(
                event: federationConnectionRemovedEvent,
                context: context
            )

        case .delete(let federationDeleteEvent):
            FederationDeleteEventProcessor(
                event: federationDeleteEvent,
                context: context
            )
        }
    }

    // MARK: - User processors

    func makeUserProcessor(
        for userEvent: UserEvent,
        context: NSManagedObjectContext
    ) -> any UserEventProcessorProtocol {
        switch userEvent {
        case .clientAdd(let userClientAddEvent):
            UserClientAddEventProcessor(
                event: userClientAddEvent,
                context: context
            )

        case .clientRemove(let userClientRemoveEvent):
            UserClientRemoveEventProcessor(
                event: userClientRemoveEvent,
                context: context
            )

        case .connection(let userConnectionEvent):
            UserConnectionEventProcessor(
                event: userConnectionEvent,
                context: context
            )

        case .contactJoin(let userContactJoinEvent):
            UserContactJoinEventProcessor(
                event: userContactJoinEvent,
                context: context
            )

        case .delete(let userDeleteEvent):
            UserDeleteEventProcessor(
                event: userDeleteEvent,
                context: context
            )

        case .legalholdDisable(let userLegalholdDisableEvent):
            UserLegalholdDisableEventProcessor(
                event: userLegalholdDisableEvent,
                context: context
            )

        case .legalholdEnable(let userLegalholdEnableEvent):
            UserLegalholdEnableEventProcessor(
                event: userLegalholdEnableEvent,
                context: context
            )

        case .legalholdRequest(let userLegalholdRequestEvent):
            UserLegalholdRequestEventProcessor(
                event: userLegalholdRequestEvent,
                context: context
            )

        case .propertiesSet(let userPropertiesSetEvent):
            UserPropertiesSetEventProcessor(
                event: userPropertiesSetEvent,
                context: context
            )

        case .propertiesDelete(let userPropertiesDeleteEvent):
            UserPropertiesDeleteEventProcessor(
                event: userPropertiesDeleteEvent,
                context: context
            )

        case .pushRemove:
            UserPushRemoveEventProcessor(
                context: context
            )

        case .update(let userUpdateEvent):
            UserUpdateEventProcessor(
                event: userUpdateEvent,
                context: context
            )
        }
    }

    // MARK: - Team processors

    func makeTeamProcessor(
        for teamEvent: TeamEvent,
        context: NSManagedObjectContext
    ) -> any TeamEventProcessorProtocol {
        switch teamEvent {
        case .delete:
            TeamDeleteEventProcessor(
                context: context
            )

        case .memberLeave(let teamMemberLeaveEvent):
            TeamMemberLeaveEventProcessor(
                event: teamMemberLeaveEvent,
                context: context
            )

        case .memberUpdate(let teamMemberUpdateEvent):
            TeamMemberUpdateEventProcessor(
                event: teamMemberUpdateEvent,
                context: context
            )
        }
    }

}
