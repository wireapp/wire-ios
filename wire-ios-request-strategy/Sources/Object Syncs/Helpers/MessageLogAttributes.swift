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

import CoreData
import WireDataModel

/// Provides log attributes for messages of supported message types.
struct MessageLogAttributes {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func logAttributes(_ message: ZMClientMessage) async -> LogAttributes {
        let messageAttributes: LogAttributes = await context.perform {
            [
                LogAttributesKey.nonce.rawValue: message.nonce?.safeForLoggingDescription ?? "<nil>",
                LogAttributesKey.messageType.rawValue: message.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
                LogAttributesKey.conversationId.rawValue: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
            ]
        }
        return messageAttributes.merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })
    }

    func logAttributes(_ message: ZMAssetClientMessage) async -> LogAttributes {
        let messageAttributes: LogAttributes = await context.perform {
            [
                LogAttributesKey.nonce.rawValue: message.nonce?.safeForLoggingDescription ?? "<nil>",
                LogAttributesKey.messageType.rawValue: message.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
                LogAttributesKey.conversationId.rawValue: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
            ]
        }
        return messageAttributes.merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })
    }

    func logAttributes(_ message: GenericMessageEntity) async -> LogAttributes {
        let messageAttributes: LogAttributes = await context.perform {
            [
                LogAttributesKey.nonce.rawValue: message.message.safeIdForLoggingDescription,
                LogAttributesKey.messageType.rawValue: message.message.safeTypeForLoggingDescription,
                LogAttributesKey.conversationId.rawValue: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
            ]
        }
        return messageAttributes.merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })
    }

    // MARK: Helpers

    /// Tries to call `logAttributes` on a supported type. Asserts if type is not supported.
    func logAttributes(_ message: any SendableMessage) async -> LogAttributes {
        await logAttributesFromAny(message)
    }

    /// Tries to call `logAttributes` on a supported type. Asserts if type is not supported.
    func logAttributes(_ message: any ProteusMessage) async -> LogAttributes {
        await logAttributesFromAny(message)
    }

    private func logAttributesFromAny(_ message: Any) async -> LogAttributes {
        if let clientMessage = message as? ZMClientMessage {
            return await logAttributes(clientMessage)
        }

        if let assetClientMessage = message as? ZMAssetClientMessage {
            return await logAttributes(assetClientMessage)
        }

        if let genericMessage = message as? GenericMessageEntity {
            return await logAttributes(genericMessage)
        }

        assertionFailure("cannot find a supported type of message '\(type(of: message))'")
        return [:]
    }
}
