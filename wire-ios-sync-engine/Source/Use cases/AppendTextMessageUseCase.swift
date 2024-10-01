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

public protocol AppendTextMessageUseCaseProtocol {

    func invoke<Conversation: MessageAppendableConversation>(
        text: String,
        mentions: [Mention],
        replyingTo: ZMConversationMessage?,
        in conversation: Conversation,
        fetchLinkPreview: Bool
    ) throws
}

public struct AppendTextMessageUseCase: AppendTextMessageUseCaseProtocol {

    let analyticsService: AnalyticsService?

    public init(analyticsService: AnalyticsService?) {
        self.analyticsService = analyticsService
    }

    public func invoke<Conversation: MessageAppendableConversation>(
        text: String,
        mentions: [Mention],
        replyingTo: ZMConversationMessage?,
        in conversation: Conversation,
        fetchLinkPreview: Bool
    ) throws {
        try conversation.appendText(
            content: text,
            mentions: mentions,
            replyingTo: replyingTo,
            fetchLinkPreview: fetchLinkPreview,
            nonce: UUID()
        )
        conversation.draftMessage = nil
        analyticsService?.trackEvent(
            .conversationContribution(
                .textMessage,
                conversationType: .init(conversation.conversationType),
                conversationSize: UInt(conversation.localParticipants.count)
            )
        )
    }
}
