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

import Foundation
import WireAnalytics
import WireDataModel

extension ZMUserSession: WireCallCenterCallStateObserver {
    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: any UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {

        switch (callState, previousCallState) {
        case (.outgoing, _):
            let isVideoCall = isVideoCall(for: conversation)
            trackCallInitialized(isVideo: isVideoCall, conversationType: conversation.conversationType)
        case (.answered(_), .incoming(video: let isVideoCall, shouldRing: _, degraded: _)):
            trackCallJoined(isVideo: isVideoCall, conversationType: conversation.conversationType)

        default:
            break
        }
    }

    private func isVideoCall(for conversation: ZMConversation) -> Bool {
        return conversation.voiceChannel?.isVideoCall ?? false
    }

    private func trackCallInitialized(isVideo: Bool, conversationType: ZMConversationType) {
        let event = AnalyticsEvent.callInitialized(isVideo: isVideo, conversationType: mapConversationType(conversationType))
        trackAnalyticsEvent(event)
    }

    private func trackCallJoined(isVideo: Bool, conversationType: ZMConversationType) {
        let event = AnalyticsEvent.callJoined(isVideo: isVideo, conversationType: mapConversationType(conversationType))
        trackAnalyticsEvent(event)
    }

    private func mapConversationType(_ type: ZMConversationType) -> ConversationType {
        switch type {
        case .group:
            return .group
        case .oneOnOne:
            return .oneOnOne
        default:
            return .unknown
        }
    }
}
