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

import WireAnalytics
import WireDataModel
import WireFoundation

public protocol AppendFileMessageUseCaseProtocol {
    func invoke(
        with fileMetadata: ZMFileMetadata,
        in conversation: some MessageAppendableConversation
    ) throws
}

public struct AppendFileMessageUseCase: AppendFileMessageUseCaseProtocol {

    weak var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?

    public init(analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?) {
        self.analyticsEventTracker = analyticsEventTracker
    }

    public func invoke(
        with fileMetadata: ZMFileMetadata,
        in conversation: some MessageAppendableConversation
    ) throws {
        let message = try conversation.appendFile(with: fileMetadata, nonce: UUID())

        var contributionType: ConversationContributionType = .fileMessage

        if let fileMessageData = message.fileMessageData {
            if fileMessageData.isVideo {
                contributionType = .videoMessage
            } else if fileMessageData.isAudio {
                contributionType = .audioMessage
            } else if fileMessageData.isPDF {
                contributionType = .fileMessage
            }

        }

        analyticsEventTracker?.trackEvent(
            .Contributed.conversationContribution(
                contributionType,
                conversationType: .init(conversation.conversationType),
                conversationSize: conversation.localParticipants.count
            )
        )
    }

}
