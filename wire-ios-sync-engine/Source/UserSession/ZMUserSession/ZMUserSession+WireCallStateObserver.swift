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

struct CallInfo {
    var toggledVideo: Bool
}

extension ZMUserSession: WireCallCenterCallStateObserver {

    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: any UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        guard let conversationId = conversation.remoteIdentifier else { return }

        switch callState {
        case .outgoing:
            let isVideo = conversation.voiceChannel?.isVideoCall ?? false
            callInfos[conversationId] = CallInfo(toggledVideo: isVideo)
            trackCallInitialized(isVideo: isVideo, conversationType: conversation.conversationType)
        case .answered:
            if let callInfo = callInfos[conversationId] {
                trackCallJoined(isVideo: callInfo.toggledVideo, conversationType: conversation.conversationType)
            }
        default:
            break
        }
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

