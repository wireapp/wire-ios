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

extension AnalyticsType {
    public func tagActionOnPushNotification(conversation: ZMConversation?, action: ConversationMediaAction) {
        guard let conversation else {
            return
        }
        var attributes = conversation.ephemeralTrackingAttributes
        attributes["action"] = action.attributeValue
        attributes["conversation_type"] = conversation.conversationType.analyticsType
        attributes["with_service"] = conversation.includesServiceUser ? "true" : "false"
        tagEvent("contributed", attributes: attributes as! [String: NSObject])
    }
}

extension ZMConversation {
    @objc public var ephemeralTrackingAttributes: [String: Any] {
        if let timeout = activeMessageDestructionTimeoutValue {
            [
                "is_ephemeral": true,
                "ephemeral_time": Int(timeout.rawValue),
            ]
        } else {
            ["is_ephemeral": false]
        }
    }

    /// Whether the conversation includes at least 1 service user.
    @objc public var includesServiceUser: Bool {
        localParticipants.any { $0.isServiceUser }
    }
}

extension ZMConversationType {
    var analyticsType: String {
        switch self {
        case .oneOnOne:
            "one_to_one"
        case .group:
            "group"
        default:
            ""
        }
    }
}

// MARK: - ConversationMediaAction

public enum ConversationMediaAction: UInt {
    case text, photo, audioCall, videoCall, gif, ping, fileTransfer, videoMessage, audioMessage, location

    // MARK: Public

    public var attributeValue: String {
        switch self {
        case .text:         "text"
        case .photo:        "photo"
        case .audioCall:    "audio_call"
        case .videoCall:    "video_call"
        case .gif:          "giphy"
        case .ping:         "ping"
        case .fileTransfer: "file"
        case .videoMessage: "video"
        case .audioMessage: "audio"
        case .location:     "location"
        }
    }
}
