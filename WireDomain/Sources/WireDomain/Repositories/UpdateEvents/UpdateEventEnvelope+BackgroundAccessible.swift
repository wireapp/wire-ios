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

import WireNetwork

extension UpdateEventEnvelope {
    var isBackgroundAccessible: Bool {
        !events.isEmpty && events.allSatisfy(\.hasCallingContent)
    }
}

private extension UpdateEvent {

    var hasCallingContent: Bool {

        switch self {
        case let .conversation(.proteusMessageAdd(eventData)):
            eventData.hasCallingContent
        case let .conversation(.mlsMessageAdd(eventData)):
            eventData.hasCallingContent
        default:
            false
        }
    }
}

private extension ConversationProteusMessageAddEvent {

    var hasCallingContent: Bool {
        guard
            let decryptedMessage = message.decryptedMessage,
            let message = try? ProtobufMessageDecoder().extractProteusMessageContent(
                from: decryptedMessage,
                externalData: externalData
            )
        else {
            return false
        }

        return message.hasCalling
    }

}

private extension ConversationMLSMessageAddEvent {

    var hasCallingContent: Bool {
        for decryptedMessage in decryptedMessages {
            guard let message = try? ProtobufMessageDecoder().extractMLSMessageContent(
                from: decryptedMessage.message
            ) else {
                continue
            }

            if message.hasCalling {
                return true
            }
        }

        return false
    }

}
