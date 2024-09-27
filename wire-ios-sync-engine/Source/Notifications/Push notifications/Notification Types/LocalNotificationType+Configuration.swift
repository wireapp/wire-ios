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

extension LocalNotificationType {
    func category(hasTeam: Bool, encryptionAtRestEnabled: Bool) -> PushNotificationCategory {
        PushNotificationCategory(notificationType: self)
            .addEncryptionAtRestIfNeeded(encryptionAtRestEnabled: encryptionAtRestEnabled)
            .addMuteIfNeeded(hasTeam: hasTeam)
    }

    var sound: NotificationSound {
        switch self {
        case let .calling(callState):
            switch callState {
            case .incoming:
                .call
            default:
                .newMessage
            }

        case .event:
            .newMessage

        case let .message(contentType):
            switch contentType {
            case .knock:
                .ping
            default:
                .newMessage
            }

        case .failedMessage, .availabilityBehaviourChangeAlert:
            .newMessage
        }
    }
}

extension PushNotificationCategory {
    fileprivate init(notificationType: LocalNotificationType) {
        switch notificationType {
        case let .calling(callState):
            self.init(callState: callState)
        case let .event(eventType):
            self.init(eventType: eventType)
        case let .message(contentType):
            self.init(contentType: contentType)
        case .failedMessage:
            self = .conversation
        case .availabilityBehaviourChangeAlert:
            self = .alert
        }
    }

    fileprivate init(callState: CallState) {
        switch callState {
        case .incoming:
            self = .incomingCall
        case .terminating(reason: .timeout):
            self = .missedCall
        default:
            self = .conversation
        }
    }

    fileprivate init(eventType: LocalNotificationEventType) {
        switch eventType {
        case .connectionRequestPending, .conversationCreated:
            self = .connect
        default:
            self = .conversation
        }
    }

    fileprivate init(contentType: LocalNotificationContentType) {
        switch contentType {
        case .audio, .video, .fileUpload, .image, .text, .location:
            self = .conversationWithLike
        case .hidden:
            self = .alert
        default:
            self = .conversation
        }
    }

    fileprivate func addMuteIfNeeded(hasTeam: Bool) -> Self {
        guard !hasTeam else { return self }

        switch self {
        case .conversation:
            return .conversationWithMute
        case .conversationWithLike:
            return .conversationWithLikeAndMute
        case .conversationUnderEncryptionAtRest:
            return .conversationUnderEncryptionAtRestWithMute
        default:
            return self
        }
    }

    fileprivate func addEncryptionAtRestIfNeeded(encryptionAtRestEnabled: Bool) -> Self {
        guard encryptionAtRestEnabled else { return self }

        switch self {
        case .conversation, .conversationWithLike:
            return .conversationUnderEncryptionAtRest
        case .conversationWithMute, .conversationWithLikeAndMute:
            return .conversationUnderEncryptionAtRestWithMute
        default:
            return self
        }
    }
}
