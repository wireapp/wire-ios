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

enum MessageErrorHelper {
    static func errorMessage(_ message: ConversationMessage) -> String? {

        let isSentBySelfUser = message.senderUser?.isSelfUser == true
        let failedToSend = message.deliveryState == .failedToSend && isSentBySelfUser

        guard failedToSend, isSentBySelfUser else {
            return nil
        }

        typealias Message = L10n.Localizable.Content.System.FailedtosendMessage

        return switch message.expirationReason {
        case .none, .other, .timeout:
            Message.generalReason
        case .federationRemoteError:
            Message.federationRemoteErrorReason(
                message.conversationLike?.domain ?? "",
                WireURLs.shared.unreachableBackendInfo.absoluteString
            )
        case .cancelled:
            Message.userCancelledUploadReason
        }
    }
}
