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

import Foundation
import WireDataModel
import WireFoundation
import WireLogging

extension ZMUserSession: WireCallCenterCallStateObserver {

    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: any UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        // Prevent duplicate tracking if state hasn't changed
        guard callState != previousCallState else { return }

        let isVideo = conversation.voiceChannel?.isVideoCall ?? false
        let conversationType = AnalyticsEvent.Segmentation.Conversation.ConversationType(conversation.conversationType)
        guard let conversationType else {
            return analyiticsLogger.error(
                "ZMUserSession.callCenterDidChange: unexpected conversation type: \(conversation.conversationType)"
            )
        }

        switch callState {
        case .outgoing:
            trackAnalyticsEvent(.Calling.initiatedCall(isVideo: isVideo, conversationType: conversationType))
        case .answered:
            // Currently, there is a limitation where we cannot track if isVideo is on or off for group calls.
            // This tracking is only possible in one-on-one calls.
            trackAnalyticsEvent(.Calling.joinedCall(isVideo: isVideo, conversationType: conversationType))
        default:
            break
        }
    }
}
