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
    var selectedAccount: Account { get }
    var sharedUserDefaults: UserDefaults { get }
    var userID: UUID { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var conversationLocalStore: any ConversationLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
}

protocol GenerateNotificationStepFactory {
    func generateNotification(
        eventsStream: AsyncStream<[UpdateEvent]>
    ) async throws
}

final class GenerateNotificationStep: Component<GenerateNotificationDependency> {

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
        ConversationEventNotificationBuilder(
            userID: <#T##UUID#>,
            userDefaults: <#T##UserDefaults#>,
            userLocalStore: <#T##any UserLocalStoreProtocol#>,
            conversationLocalStore: <#T##any ConversationLocalStoreProtocol#>,
            messageLocalStore: <#T##any MessageLocalStoreProtocol#>,
            callKitNotificationBuilder: <#T##CallKitNotificationBuilder#>,
            callNotificationBuilder: <#T##CallNotificationBuilder#>,
            conversationMLSMessageAddEventNotificationBuilder: <#T##ConversationMLSMessageAddEventNotificationBuilder#>,
            conversationProteusMessageAddEventNotificationBuilder: <#T##ConversationProteusMessageAddEventNotificationBuilder#>,
            conversationMemberLeaveEventNotificationBuilder: <#T##ConversationMemberLeaveEventNotificationBuilder#>,
            conversationMemberJoinEventNotificationBuilder: <#T##ConversationMemberJoinEventNotificationBuilder#>,
            conversationCreateEventNotificationBuilder: <#T##ConversationCreateEventNotificationBuilder#>,
            conversationDeleteEventNotificationBuilder: <#T##ConversationDeleteEventNotificationBuilder#>,
            conversationMessageTimerUpdateEventNotificationBuilder: <#T##ConversationMessageTimerUpdateEventNotificationBuilder#>)
    }
    
    private var userEventNotificationBuilder: UserNotificationBuilder {
        UserNotificationBuilder(event: <#T##UserEvent#>, userLocalStore: <#T##any UserLocalStoreProtocol#>)
        
    }
}
