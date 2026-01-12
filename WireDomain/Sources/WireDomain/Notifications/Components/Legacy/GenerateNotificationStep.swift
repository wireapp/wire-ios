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

// TODO: [WPB-19818] delete when multibackend is released

import NeedleFoundation
import UserNotifications
import WireDataModel
import WireNetwork

protocol GenerateNotificationDependency: Dependency {
    var sharedUserDefaults: UserDefaults { get }
    var userID: UUID { get }
    var eventID: UUID { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var conversationLocalStore: any ConversationLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
}

protocol GenerateNotificationStepProtocol {
    func generateNotification(
        eventsStream: AsyncStream<[UpdateEvent]>
    ) async throws
}

final class GenerateNotificationStep: Component<GenerateNotificationDependency>, GenerateNotificationStepProtocol {

    func generateNotification(
        eventsStream: AsyncStream<[UpdateEvent]>
    ) async throws {

        let generateNotificationUseCase = GenerateNotificationUseCase(
            conversationEventBuilder: conversationEventNotificationBuilder,
            userEventBuilder: userEventNotificationBuilder,
            eventID: dependency.eventID
        )

        let userNotifications = try await generateNotificationUseCase.invoke(
            updateEvents: eventsStream
        )

        try await showNotificationStep.showNotifications(
            userNotifications
        )
    }

    // MARK: - Children

    var showNotificationStep: ShowNotificationStep {
        ShowNotificationStep(parent: self)
    }

}

extension GenerateNotificationStep {
    private var conversationEventNotificationBuilder: ConversationEventNotificationBuilder {
        let validator = ConversationEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore,
            conversationLocalStore: dependency.conversationLocalStore,
            messageLocalStore: dependency.messageLocalStore
        )

        return ConversationEventNotificationBuilder(
            validator: validator,
            conversationMessageAddEventNotificationBuilder: conversationMessageAddEventNotificationBuilder,
            conversationMemberLeaveEventNotificationBuilder: conversationMemberLeaveEventNotificationBuilder,
            conversationMemberJoinEventNotificationBuilder: conversationMemberJoinEventNotificationBuilder,
            conversationCreateEventNotificationBuilder: conversationCreateEventNotificationBuilder,
            conversationDeleteEventNotificationBuilder: conversationDeleteEventNotificationBuilder,
            conversationMessageTimerUpdateEventNotificationBuilder: conversationMessageTimerUpdateEventNotificationBuilder
        )
    }

    var conversationMemberLeaveEventNotificationBuilder: ConversationMemberLeaveEventNotificationBuilder {
        let context = ConversationMemberLeaveEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = ConversationMemberLeaveEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore
        )

        return ConversationMemberLeaveEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationMemberJoinEventNotificationBuilder: ConversationMemberJoinEventNotificationBuilder {
        let context = ConversationMemberJoinEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = ConversationMemberJoinEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore
        )

        return ConversationMemberJoinEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationMessageTimerUpdateEventNotificationBuilder: ConversationMessageTimerUpdateEventNotificationBuilder {
        let context = ConversationMessageTimerUpdateEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = ConversationMessageTimerUpdateEventNotificationBuilder.Validator()

        return ConversationMessageTimerUpdateEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationCreateEventNotificationBuilder: ConversationCreateEventNotificationBuilder {
        let context = ConversationCreateEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = ConversationCreateEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore
        )

        return ConversationCreateEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationDeleteEventNotificationBuilder: ConversationDeleteEventNotificationBuilder {
        let context = ConversationDeleteEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = ConversationDeleteEventNotificationBuilder.Validator(
            conversationLocalStore: dependency.conversationLocalStore
        )

        return ConversationDeleteEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationMessageAddEventNotificationBuilder: ConversationMessageAddEventNotificationBuilder {

        let context = ConversationMessageAddEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore
        )

        let validator = ConversationMessageAddEventNotificationBuilder.Validator(
            conversationLocalStore: dependency.conversationLocalStore
        )

        return ConversationMessageAddEventNotificationBuilder(
            context: context,
            validator: validator,
            conversationCallingEventNotificationBuilder: conversationCallingEventNotificationBuilder,
            conversationAudioMessageNotificationBuilder: conversationAudioMessageNotificationBuilder,
            conversationEphemeralMessageNotificationBuilder: conversationEphemeralMessageNotificationBuilder,
            conversationFileUploadMessageNotificationBuilder: conversationFileUploadMessageNotificationBuilder,
            conversationHiddenMessageNotificationBuilder: conversationHiddenMessageNotificationBuilder,
            conversationImageMessageNotificationBuilder: conversationImageMessageNotificationBuilder,
            conversationLocationMessageNotificationBuilder: conversationLocationMessageNotificationBuilder,
            conversationPingMessageNotificationBuilder: conversationPingMessageNotificationBuilder,
            conversationVideoMessageNotificationBuilder: conversationVideoMessageNotificationBuilder,
            conversationTextMessageNotificationBuilder: conversationTextMessageNotificationBuilder
        )
    }

    var conversationAudioMessageNotificationBuilder: ConversationAudioMessageNotificationBuilder {
        let context = ConversationAudioMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationAudioMessageNotificationBuilder(context: context)
    }

    var conversationVideoMessageNotificationBuilder: ConversationVideoMessageNotificationBuilder {
        let context = ConversationVideoMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationVideoMessageNotificationBuilder(context: context)
    }

    var conversationPingMessageNotificationBuilder: ConversationPingMessageNotificationBuilder {
        let context = ConversationPingMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationPingMessageNotificationBuilder(context: context)
    }

    var conversationLocationMessageNotificationBuilder: ConversationLocationMessageNotificationBuilder {
        let context = ConversationLocationMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationLocationMessageNotificationBuilder(context: context)
    }

    var conversationHiddenMessageNotificationBuilder: ConversationHiddenMessageNotificationBuilder {
        let context = ConversationHiddenMessageNotificationBuilder.Context(
            userLocalStore: dependency.userLocalStore,
            conversationLocalStore: dependency.conversationLocalStore
        )

        return ConversationHiddenMessageNotificationBuilder(context: context)
    }

    var conversationFileUploadMessageNotificationBuilder: ConversationFileUploadMessageNotificationBuilder {
        let context = ConversationFileUploadMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationFileUploadMessageNotificationBuilder(context: context)
    }

    var conversationImageMessageNotificationBuilder: ConversationImageMessageNotificationBuilder {
        let context = ConversationImageMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationImageMessageNotificationBuilder(context: context)
    }

    var conversationEphemeralMessageNotificationBuilder: ConversationEphemeralMessageNotificationBuilder {
        let context = ConversationEphemeralMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore,
            messageLocalStore: dependency.messageLocalStore
        )

        return ConversationEphemeralMessageNotificationBuilder(context: context)
    }

    var conversationTextMessageNotificationBuilder: ConversationTextMessageNotificationBuilder {
        let context = ConversationTextMessageNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore,
            messageLocalStore: dependency.messageLocalStore
        )

        return ConversationTextMessageNotificationBuilder(context: context)
    }

    var conversationCallingEventNotificationBuilder: ConversationCallingEventNotificationBuilder {
        let validator = ConversationCallingEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore,
            conversationLocalStore: dependency.conversationLocalStore,
            userDefaults: dependency.sharedUserDefaults
        )

        let context = ConversationCallingEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        return ConversationCallingEventNotificationBuilder(
            context: context,
            validator: validator,
            accountID: dependency.userID
        )
    }

    private var userEventNotificationBuilder: UserEventNotificationBuilder {
        let validator = UserEventNotificationBuilder.Validator()

        return UserEventNotificationBuilder(
            validator: validator,
            userConnectionEventNotificationBuilder: userConnectionEventNotificationBuilder,
            userContactJoinEventNotificationBuilder: userContactJoinEventNotificationBuilder
        )

    }

    private var userContactJoinEventNotificationBuilder: UserContactJoinEventNotificationBuilder {
        let context = UserContactJoinEventNotificationBuilder.Context()
        let validator = UserContactJoinEventNotificationBuilder.Validator()

        return UserContactJoinEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    private var userConnectionEventNotificationBuilder: UserConnectionEventNotificationBuilder {

        let context = UserConnectionEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore
        )

        let validator = UserConnectionEventNotificationBuilder.Validator()

        return UserConnectionEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }
}
