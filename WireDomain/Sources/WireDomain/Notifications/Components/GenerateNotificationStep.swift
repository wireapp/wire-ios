//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import NeedleFoundation
import UserNotifications
import WireAPI
import WireDataModel

protocol GenerateNotificationDependency: Dependency {
    var contentHandler: (UNNotificationContent) -> Void { get }
    var accountManager: AccountManager { get }
    var sharedUserDefaults: UserDefaults { get }
    var userID: UUID! { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var conversationLocalStore: any ConversationLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
}

protocol GenerateNotificationStepFactory {
    func generateNotification(
        eventsStream: AsyncStream<[UpdateEvent]>
    ) async throws
}

final class GenerateNotificationStep: Component<GenerateNotificationDependency>, GenerateNotificationStepFactory {

    func generateNotification(
        eventsStream: AsyncStream<[UpdateEvent]>
    ) async throws {

        let generateNotificationUseCase = GenerateNotificationUseCase(
            conversationEventBuilder: conversationEventNotificationBuilder,
            userEventBuilder: userEventNotificationBuilder
        )

        let userNotifications = try await generateNotificationUseCase.invoke(
            updateEvents: eventsStream
        )

        try await showNotificationStep.showNotifications(
            userNotifications
        )
    }

    // MARK: - Children

    var showNotificationStep: any ShowNotificationStepFactory {
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
            conversationCallingEventNotificationBuilder: conversationCallingEventNotificationBuilder,
            conversationMLSMessageAddEventNotificationBuilder: conversationMLSMessageAddEventNotificationBuilder,
            conversationProteusMessageAddEventNotificationBuilder: conversationProteusMessageAddEventNotificationBuilder,
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

    var conversationMLSMessageAddEventNotificationBuilder: ConversationMLSMessageAddEventNotificationBuilder {

        let context = ConversationMLSMessageAddEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore,
            messageLocalStore: dependency.messageLocalStore
        )

        let validator = ConversationMLSMessageAddEventNotificationBuilder.Validator(
            conversationLocalStore: dependency.conversationLocalStore
        )

        return ConversationMLSMessageAddEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationProteusMessageAddEventNotificationBuilder: ConversationProteusMessageAddEventNotificationBuilder {

        let context = ConversationProteusMessageAddEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore,
            messageLocalStore: dependency.messageLocalStore
        )

        let validator = ConversationProteusMessageAddEventNotificationBuilder.Validator(
            conversationLocalStore: dependency.conversationLocalStore
        )

        return ConversationProteusMessageAddEventNotificationBuilder(
            context: context,
            validator: validator
        )
    }

    var conversationCallingEventNotificationBuilder: ConversationCallingEventNotificationBuilder {
        let validator = ConversationCallingEventNotificationBuilder.Validator(
            userLocalStore: dependency.userLocalStore,
            conversationLocalStore: dependency.conversationLocalStore,
            userDefaults: dependency.sharedUserDefaults
        )

        let context = ConversationCallingEventNotificationBuilder.Context(
            conversationLocalStore: dependency.conversationLocalStore,
            userLocalStore: dependency.userLocalStore,
            userDefaults: dependency.sharedUserDefaults
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
