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
    associatedtype Conversation: MessageAppendableConversation

    func invoke(
        text: String,
        mentions: [Mention],
        replyingTo: ZMConversationMessage?,
        in conversation: Conversation,
        fetchLinkPreview: Bool
    ) throws
}

public struct AppendTextMessageUseCase<Conversation>: AppendTextMessageUseCaseProtocol
where Conversation: MessageAppendableConversation {

    let analyticsSession: AnalyticsSessionProtocol?

    public func invoke(
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
        analyticsSession?.trackEvent(
            ContributedEvent(
                contributionType: .textMessage,
                conversationType: .init(conversation.conversationType),
                conversationSize: UInt(
                    conversation.localParticipants.count
                )
            )
        )
    }
}

public protocol MessageAppendableConversation {

    var conversationType: ZMConversationType { get }
    var localParticipants: Set<ZMUser> { get }
    var draftMessage: DraftMessage? { get nonmutating set }

    @discardableResult
    func appendText(
        content: String,
        mentions: [Mention],
        replyingTo quotedMessage: (any ZMConversationMessage)?,
        fetchLinkPreview: Bool,
        nonce: UUID
    ) throws -> any ZMConversationMessage

    @discardableResult
    func appendKnock(nonce: UUID) throws -> any ZMConversationMessage

}

extension ZMConversation: MessageAppendableConversation {

}
