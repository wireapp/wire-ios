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

import WireAnalytics
import WireDataModel

public protocol ToggleMessageReactionUseCaseProtocol {

    func invoke<Conversation: MessageAppendableConversation>(
        _ reaction: String,
        for message: ZMConversationMessage,
        in conversation: Conversation
    )
}

public struct ToggleMessageReactionUseCase: ToggleMessageReactionUseCaseProtocol {

    weak var analyticsEventTracker: (any AnalyticsEventTracker)?

    public init(analyticsEventTracker: (any AnalyticsEventTracker)?) {
        self.analyticsEventTracker = analyticsEventTracker
    }

    public func invoke<Conversation: MessageAppendableConversation>(
        _ reaction: String,
        for message: ZMConversationMessage,
        in conversation: Conversation
    ) {
        let currentReactions = message.selfUserReactions()
        if currentReactions.contains(reaction) {
            ZMMessage.removeReaction(reaction, from: message)
        } else {
            ZMMessage.addReaction(reaction, to: message)
            if reaction == "❤️" {
                analyticsEventTracker?.trackEvent(
                    .conversationContribution(
                        .likeMessage,
                        conversationType: .init(conversation.conversationType),
                        conversationSize: UInt(conversation.localParticipants.count)
                    )
                )
            }
        }
    }
}
