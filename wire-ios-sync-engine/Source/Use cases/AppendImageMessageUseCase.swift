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
import WireLogging

public protocol AppendImageMessageUseCaseProtocol {

    func invoke<Conversation: MessageAppendableConversation>(
        withImageData imageData: Data,
        in conversation: Conversation
    ) throws
}

public struct AppendImageMessageUseCase: AppendImageMessageUseCaseProtocol {

    weak var analyticsEventTracker: (any AnalyticsEventTracker)?
    var analyticsLogger: WireLogger

    public init(
        analyticsEventTracker: (any AnalyticsEventTracker)?,
        analyticsLogger: WireLogger
    ) {
        self.analyticsEventTracker = analyticsEventTracker
        self.analyticsLogger = analyticsLogger
    }

    public func invoke(
        withImageData imageData: Data,
        in conversation: some MessageAppendableConversation
    ) throws {
        try conversation.appendImage(from: imageData, nonce: UUID())

        let conversationType = SegmentationEntry.Conversation.ConversationType(conversation.conversationType)
        guard let conversationType else {
            return analyticsLogger.error(
                "AppendImageMessageUseCase.invoke: conversation type \(conversation.conversationType) cannot be " +
                "converted to SegmentationEntry.Conversation.ConversationType."
            )
        }

        analyticsEventTracker?.trackEvent(
            .Contributed.conversationContribution(
                .imageMessage,
                conversationType: conversationType,
                conversationSize: conversation.localParticipants.count
            )
        )
    }

}
