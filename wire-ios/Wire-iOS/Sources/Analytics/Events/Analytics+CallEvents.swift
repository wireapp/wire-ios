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

import UIKit
import WireDataModel

enum CallEvent {
    case initiated,
         received,
         answered,
         established,
         ended(reason: String),
         screenSharing(duration: TimeInterval)
}

extension CallEvent {
    var eventName: String {
        switch self {
        case .initiated: "calling.initiated_call"
        case .received: "calling.received_call"
        case .answered: "calling.joined_call"
        case .established: "calling.established_call"
        case .ended: "calling.ended_call"
        case .screenSharing: "calling.screen_share"
        }
    }
}

extension Analytics {
    func tagCallQualityReview(_ feedback: CallQualitySurveyReview) {
        var attributes: [String: NSObject] = [:]
        attributes["label"] = feedback.label
        attributes["score"] = feedback.score
        attributes["ignore-reason"] = feedback.ignoreReason

        tagEvent("calling.call_quality_review", attributes: attributes)
    }

    func tag(
        callEvent: CallEvent,
        in conversation: ZMConversation,
        callInfo: CallInfo
    ) {
        tagEvent(
            callEvent.eventName,
            attributes: attributes(for: callEvent, callInfo: callInfo, conversation: conversation)
        )
    }

    private func attributes(
        for event: CallEvent,
        callInfo: CallInfo,
        conversation: ZMConversation
    ) -> [String: Any] {
        var attributes = conversation.attributesForConversation

        attributes.merge(attributesForUser(in: conversation)) { _, new in new }
        attributes.merge(attributesForParticipants(in: conversation)) { _, new in new }
        attributes.merge(attributesForCallParticipants(with: callInfo)) { _, new in new }
        attributes.merge(attributesForVideo(with: callInfo)) { _, new in new }
        attributes.merge(attributesForDirection(with: callInfo)) { _, new in new }

        switch event {
        case let .ended(reason: reason):
            attributes.merge(attributesForSetupTime(with: callInfo)) { _, new in new }
            attributes.merge(attributesForCallDuration(with: callInfo)) { _, new in new }
            attributes.merge(attributesForVideoToogle(with: callInfo)) { _, new in new }
            attributes.merge(["reason": reason]) { _, new in new }

        case let .screenSharing(duration):
            attributes["screen_share_direction"] = "incoming"
            attributes["screen_share_duration"] = Int(round(duration / 5)) * 5

        default:
            break
        }

        return attributes
    }

    private func attributesForUser(in conversation: ZMConversation) -> [String: Any] {
        guard let selfUser = SelfUser.provider?.providedSelfUser else { return [:] }
        var userType = if selfUser.isWirelessUser {
            "temporary_guest"
        } else if selfUser.isGuest(in: conversation) {
            "guest"
        } else {
            "user"
        }

        return ["user_type": userType]
    }

    private func attributesForVideoToogle(with callInfo: CallInfo) -> [String: Any] {
        ["AV_switch_toggled": callInfo.toggledVideo ? true : false]
    }

    private func attributesForVideo(with callInfo: CallInfo) -> [String: Any] {
        ["call_video": callInfo.video]
    }

    private func attributesForDirection(with callInfo: CallInfo) -> [String: Any] {
        ["direction": callInfo.outgoing ? "outgoing" : "incoming"]
    }

    private func attributesForParticipants(in conversation: ZMConversation) -> [String: Any] {
        ["conversation_participants": conversation.localParticipants.count]
    }

    private func attributesForCallParticipants(with callInfo: CallInfo) -> [String: Any] {
        ["conversation_participants_in_call_max": callInfo.maximumCallParticipants]
    }

    private func attributesForSetupTime(with callInfo: CallInfo) -> [String: Any] {
        guard let establishedDate = callInfo.establishedDate, let connectingDate = callInfo.connectingDate else {
            return [:]
        }
        return ["setup_time": Int(establishedDate.timeIntervalSince(connectingDate))]
    }

    private func attributesForCallDuration(with callInfo: CallInfo) -> [String: Any] {
        guard let establishedDate = callInfo.establishedDate else {
            return [:]
        }
        return ["duration": Int(-establishedDate.timeIntervalSinceNow)]
    }
}
