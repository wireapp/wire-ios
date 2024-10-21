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

extension ZMConversation {

    public enum UpdateSelfConversationError: Error {

        case invalidConversation
        case missingLastReadTimestamp
        case missingClearedTimestamp

    }

    // MARK: - Sync upstream

    /// Append a `LastRead` message derived from a given conversation to the self conversation.
    ///
    /// - Parameters:
    ///     - conversation: The conversation from which the last read message is derived.
    ///
    /// - Throws:
    ///     - `UpdateSelfConversationError` if last read can't or shouldn't be derived from `conversation`.
    ///     - `AppendMessageError` if the last read message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public static func updateSelfConversation(withLastReadOf conversation: ZMConversation) throws -> ZMClientMessage {
        guard let lastReadTimeStamp = conversation.lastReadServerTimeStamp else {
            throw UpdateSelfConversationError.missingLastReadTimestamp
        }

        guard
            let context = conversation.managedObjectContext,
            let conversationID = conversation.qualifiedID,
            conversationID.uuid != ZMConversation.selfConversationIdentifier(in: context)
        else {
            throw UpdateSelfConversationError.invalidConversation
        }

        let lastRead = LastRead(conversationID: conversationID, lastReadTimestamp: lastReadTimeStamp)
        let messages = try sendMessageToSelfClients(lastRead, in: context)
        return messages.proteus
    }

    /// Append a `Cleared` message derived from a given conversation to the self conversation.
    ///
    /// - Parameters:
    ///     - conversation: The conversation from which the cleared message is derived.
    ///
    /// - Throws:
    ///     - `UpdateSelfConversationError` if cleared message can't or shouldn't be derived from `conversation`.
    ///     - `AppendMessageError` if the cleared message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public static func updateSelfConversation(withClearedOf conversation: ZMConversation) throws -> ZMClientMessage {
        guard let clearedTimestamp = conversation.clearedTimeStamp else {
            throw UpdateSelfConversationError.missingClearedTimestamp
        }

        guard
            let context = conversation.managedObjectContext,
            let convId = conversation.remoteIdentifier,
            convId != ZMConversation.selfConversationIdentifier(in: context)
        else {
            throw UpdateSelfConversationError.invalidConversation
        }

        let cleared = Cleared(timestamp: clearedTimestamp, conversationID: convId)
        let messages = try sendMessageToSelfClients(cleared, in: context)
        return messages.proteus
    }

    @discardableResult
    public static func sendMessageToSelfClients(
        _ content: MessageCapable,
        in context: NSManagedObjectContext
    ) throws -> (proteus: ZMClientMessage, mls: ZMClientMessage?) {
        let proteusMessage = try sendMessageOverProteusSelfConversation(
            content,
            in: context
        )

        let mlsMessage = try sendMessageOverMLSSelfConversation(
            content,
            in: context
        )

        return (proteusMessage, mlsMessage)
    }

    private static func sendMessageOverProteusSelfConversation(
        _ content: MessageCapable,
        in context: NSManagedObjectContext
    ) throws -> ZMClientMessage {
        let message = GenericMessage(content: content, nonce: UUID())
        let selfConversation = ZMConversation.selfConversation(in: context)
        return try selfConversation.appendClientMessage(with: message, expires: false, hidden: false)
    }

    private static func sendMessageOverMLSSelfConversation(
        _ content: MessageCapable,
        in context: NSManagedObjectContext
    ) throws -> ZMClientMessage? {
        guard let selfConversation = ZMConversation.fetchSelfMLSConversation(in: context) else {
            return nil
        }

        let message = GenericMessage(content: content, nonce: UUID())
        return try selfConversation.appendClientMessage(with: message, expires: false, hidden: false)
    }

    // MARK: - Sync downstream

    static func updateConversation(
        withLastReadFromSelfConversation lastRead: LastRead,
        in context: NSManagedObjectContext
    ) {
        guard let conversationID = UUID(uuidString: lastRead.conversationID) else {
            return
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: lastRead.qualifiedConversationID.domain,
            in: context
        )

        conversation.updateLastRead(
            dateFromTimestamp(lastRead.lastReadTimestamp),
            synchronize: false
        )
    }

    static func updateConversation(
        withClearedFromSelfConversation cleared: Cleared,
        in context: NSManagedObjectContext
    ) {
        guard let conversationID = UUID(uuidString: cleared.conversationID) else {
            return
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: cleared.qualifiedConversationID.domain,
            in: context
        )

        conversation.updateCleared(
            dateFromTimestamp(cleared.clearedTimestamp),
            synchronize: false
        )
    }

    private static func dateFromTimestamp(_ timestamp: Int64) -> Date {
        let interval = Double(timestamp) / 1000
        return Date(timeIntervalSince1970: interval)
    }

}
