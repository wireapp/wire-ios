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
struct MessageLogAttributesBuilder {

    private let context: NSManagedObjectContext

    // MARK: - Initialize

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - ZMClientMessage

    func logAttributes(_ message: ZMClientMessage) async -> LogAttributes {
        let attributes = await context.perform { clientMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    func syncLogAttributes(_ message: ZMClientMessage) -> LogAttributes {
        let attributes = context.performAndWait { clientMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    private func clientMessageLogAttributes(_ message: ZMClientMessage) -> LogAttributes {
        [
            .nonce: message.nonce?.safeForLoggingDescription ?? "<nil>",
            .messageType: message.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
            .conversationId: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ]
    }

    // MARK: - ZMAssetClientMessage

    func logAttributes(_ message: ZMAssetClientMessage) async -> LogAttributes {
        let attributes = await context.perform { assetClientMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    func syncLogAttributes(_ message: ZMAssetClientMessage) -> LogAttributes {
        let attributes = context.performAndWait { assetClientMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    private func assetClientMessageLogAttributes(_ message: ZMAssetClientMessage) -> LogAttributes {
        [
            .nonce: message.nonce?.safeForLoggingDescription ?? "<nil>",
            .messageType: message.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
            .conversationId: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ]
    }

    // MARK: - GenericMessageEntity

    func logAttributes(_ message: GenericMessageEntity) async -> LogAttributes {
        let attributes = await context.perform { genericMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    func syncLogAttributes(_ message: GenericMessageEntity) -> LogAttributes {
        let attributes = context.performAndWait { genericMessageLogAttributes(message) }
        return makeAttributesPublic(attributes)
    }

    private func genericMessageLogAttributes(_ message: GenericMessageEntity) -> LogAttributes {
        [
            .nonce: message.message.safeIdForLoggingDescription,
            .messageType: message.message.safeTypeForLoggingDescription,
            .conversationId: message.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ]
    }

    // MARK: - Protocol async

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

    // MARK: - Protocol sync

    /// Tries to call `logAttributes` on a supported type. Asserts if type is not supported.
    func syncLogAttributes(_ message: any ProteusMessage) -> LogAttributes {
        if let clientMessage = message as? ZMClientMessage {
            return syncLogAttributes(clientMessage)
        }

        if let assetClientMessage = message as? ZMAssetClientMessage {
            return syncLogAttributes(assetClientMessage)
        }

        if let genericMessage = message as? GenericMessageEntity {
            return syncLogAttributes(genericMessage)
        }

        assertionFailure("cannot find a supported type of message '\(type(of: message))'")
        return [:]
    }

    // MARK: Helpers

    private func makeAttributesPublic(_ attributes: LogAttributes) -> LogAttributes {
        attributes.merging(.safePublic, uniquingKeysWith: { _, new in new })
    }
}
