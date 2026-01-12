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

import GenericMessageProtocol
import WireDataModel
import WireDomain
import WireLogging
import WireNetwork

/// This migration should be used to re-process events which were received before but couldn't be deserialized due to
/// newly added message content types.
///
/// Currently incoming messages where the ``GenericMessage.content`` cannot be deserialized and the
/// ``GenericMessage.unknownStrategy`` property is set to ``GenericMessage.UnknownStrategy.warnUserAllowRetry``, are
/// stored as ``UnknownMessage`` in the database.
/// This migration fetches them, tries to reprocess the events and on success converts the messages into a
/// ``ZMClientMessage`` or ``ZMAssetClientMessage``.
struct UnknownMessageAppVersionMigration: AppVersionMigration {

    let version: SemanticVersion
    let contextProvider: ContextProvider
    let conversationLocalStore: (any ConversationLocalStoreProtocol)?
    let protobufMessageProcessor: (any ConversationProtobufMessageProcessorProtocol)?

    func perform() async throws {
        try await processUnknownMessages()
    }

    /// Processes stored unknown messages by attempting to decode them with the current protobuf definitions.
    /// This migration enables the app to process messages that were received before the app was updated
    /// with support for new message content types.
    private func processUnknownMessages() async throws {
        guard let conversationLocalStore, let protobufMessageProcessor else {
            WireLogger.session.warn("Missing dependencies for unknown message processing migration")
            return
        }

        let unknownMessageProcessingService = UnknownMessageProcessingService(
            contextProvider: contextProvider,
            conversationLocalStore: conversationLocalStore,
            protobufMessageProcessor: protobufMessageProcessor
        )

        try await unknownMessageProcessingService.processStoredUnknownMessages()
    }

}
