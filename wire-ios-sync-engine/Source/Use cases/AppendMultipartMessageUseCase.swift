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

import WireAnalytics
import WireDataModel
import WireFoundation
import WireLogging

public protocol AppendMultipartMessageUseCaseProtocol {

    func invoke(
        text: String,
        mentions: [Mention],
        replyingTo: ZMConversationMessage?,
        in conversation: ZMConversation,
        fetchLinkPreview: Bool,
        attachments: [MultipartAttachment]
    ) throws
}

public struct AppendMultipartMessageUseCase: AppendMultipartMessageUseCaseProtocol {

    // TODO: [WPB-18168] Can we avoid making this weak? There has to be a better way.
    private weak var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?

    public init(analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?) {
        self.analyticsEventTracker = analyticsEventTracker
    }

    public func invoke(
        text: String,
        mentions: [Mention],
        replyingTo: ZMConversationMessage?,
        in conversation: ZMConversation,
        fetchLinkPreview: Bool,
        attachments: [MultipartAttachment]
    ) throws {
        try conversation.appendMultipart(
            text: text,
            attachments: attachments,
            mentions: mentions,
            replyingTo: replyingTo,
            fetchLinkPreview: fetchLinkPreview,
            nonce: UUID()
        )
        conversation.draftMessage = nil

        // TODO: [WPB-18168] Track analytics event
    }
}
