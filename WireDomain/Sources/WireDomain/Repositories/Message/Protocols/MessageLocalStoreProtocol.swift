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

public import Foundation
public import WireDataModel

import GenericMessageProtocol

// sourcery: AutoMockable
/// Facilitate access to message related domain objects.
public protocol MessageLocalStoreProtocol {

    /// Adds a system message to a given conversation.
    /// - Parameters:
    ///     - messageType: The type of system message to add.
    ///     - conversationID: The conversation id.
    ///     - conversationDomain: The conversation domain.

    func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async

    /// Adds a system message (to all conversations) that inform that there are potential lost messages
    /// and that some users were added to the conversation

    func addPotentialGapSystemMessage() async throws

    /// Fetches or creates a `ZMClientMessage` locally.
    /// - Parameters:
    ///     - id: The message ID.
    ///     - conversation: The conversation the message is related to.
    ///     - sender: The message sender info.
    ///     - date: The date the message was received.

    func fetchOrCreateClientMessage(
        id: String,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date
    ) async throws -> (ZMClientMessage, isNew: Bool)

    /// Fetches or creates a `ZMAssetClientMessage` locally.
    /// - Parameters:
    ///     - id: The message ID.
    ///     - conversation: The conversation the message is related to.
    ///     - sender: The message sender info.
    ///     - date: The date the message was received.

    func fetchOrCreateAssetClientMessage(
        id: String,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date
    ) async throws -> (ZMAssetClientMessage, isNew: Bool)

    /// Adds a `ZMClientMessage` to a given conversation.
    /// - Parameters:
    ///     - clientMessage: The client message.
    ///     - isNewMessage: Whether it is a new message.
    ///     - genericMessage: The related protobuf message.
    ///     - conversation: The conversation the message is related to.
    ///     - senderID: The message sender ID.
    ///     - senderDomain: The message sender domain.

    func addClientMessage(
        _ clientMessage: ZMClientMessage,
        isNewMessage: Bool,
        genericMessage: GenericMessage,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String
    ) async

    /// Adds a `ZMAssetClientMessage` to a given conversation.
    /// - Parameters:
    ///     - clientMessage: The client message.
    ///     - isNewMessage: Whether it is a new message.
    ///     - genericMessage: The related protobuf message.
    ///     - conversation: The conversation the message is related to.
    ///     - senderID: The message sender ID.
    ///     - senderDomain: The message sender domain.

    func addAssetClientMessage(
        _ assetClientMessage: ZMAssetClientMessage,
        isNewMessage: Bool,
        genericMessage: GenericMessage,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String
    ) async

    /// Adds a placeholder for an unknown message to the conversation.
    /// This allows the message to be processed later when the app is updated with support for new message types.
    /// - Parameters:
    ///   - messageID: The unique identifier of the message
    ///   - conversationID: The ID of the conversation the message belongs to
    ///   - conversationDomain: The domain of the conversation (nil for local conversations)
    ///   - senderID: The ID of the user who sent the message
    ///   - senderDomain: The domain of the sender
    ///   - payload: The raw protobuf data that couldn't be decoded
    ///   - date: The timestamp when the message was received

    func addUnknownMessage(
        messageID: UUID,
        conversationID: UUID,
        conversationDomain: String?,
        senderID: UUID,
        senderDomain: String,
        payload: Data,
        date: Date
    ) async

    /// Checks whether a message can be added to the conversation.
    /// - Parameters:
    ///     - conversation: The conversation to add the message to.
    ///     - senderID: The message sender id.

    func canAddMessage(
        conversation: ZMConversation,
        senderID: UUID
    ) async -> Bool

    /// Deletes a given message from all of the self user's devices.
    /// - Parameters:
    ///     - hiddenMessage: The hidden message protobuf object.
    ///     - conversation: The related conversation.
    ///
    /// "Delete for me" will locally delete the message, and tell all other devices of this user to delete the message
    /// in a similar fashion.
    /// In the optimal case, no trace of that message is left on the user's devices.
    /// However, other users will still see that message.

    func deleteMessageForSelf(
        _ hiddenMessage: MessageHide,
        in conversation: ZMConversation
    ) async

    /// Recalls a previously sent message.
    /// - Parameters:
    ///     - deletedMessage: The delete message protobuf object.
    ///     - conversation: The related conversation.
    ///
    /// "Delete for everyone" will recall the message. The message is deleted locally, and all other participants
    /// devices in the conversation are requested to delete the message.
    /// In the optimal case, these devices will delete the message and replace it with a visible "delete message"
    /// placeholder.

    func deleteMessageForEveryone(
        _ deletedMessage: MessageDelete,
        in conversation: ZMConversation,
        senderID: UUID
    ) async

    /// Adds a reaction to a message.
    /// - Parameters:
    ///     - messageReaction: The message reaction protobuf object.
    ///     - conversation: The related conversation.
    ///     - senderID: The message sender id.
    ///     - date: The date the reaction was added.
    ///
    /// For instance, like or unlike a message.

    func addMessageReaction(
        _ messageReaction: GenericMessageProtocol.Reaction,
        in conversation: ZMConversation,
        senderID: UUID,
        date: Date
    ) async

    /// Adds a message confirmation to a message. This is used for read receipts.
    /// - Parameters:
    ///    - confirmation: The confirmation protobuf object.
    ///    - conversation: The related conversation.
    ///    - senderID: The message sender id.
    ///    - senderDomain: The message sender domain.
    ///    - date: The date the confirmation was added.

    func addMessageConfirmation(
        _ confirmation: GenericMessageProtocol.Confirmation,
        in conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date
    ) async

    /// Updates button states.
    /// - Parameters:
    ///     - buttonID: The id of the button.
    ///     - referenceMessageID: The id of the parent message.
    ///     - conversation: The related conversation.
    ///     - senderID: The message sender id.
    ///
    /// When someone has clicked on a button, to confirm to them that the answer has been accepted.

    func updateButtonStates(
        buttonID: String?,
        referenceMessageID: String,
        in conversation: ZMConversation,
        senderID: UUID
    ) async

    /// Edits a previously sent message.
    /// - Parameters:
    ///     - messageEdit: The protobuf message edit object.
    ///     - conversation: The related conversation.
    ///     - senderID: The message sender id.
    ///     - genericMessage: The protobuf generic message object.
    ///     - date: The date the reaction was added.
    ///
    /// Messages can be edited by the original author (user, not device) of the message.
    /// This is achieved by the author device sending another message with a request to edit the original one.

    func editMessage(
        _ messageEdit: MessageEdit,
        in conversation: ZMConversation,
        senderID: UUID,
        genericMessage: GenericMessage,
        date: Date
    ) async

    func fetchMessage(
        id: UUID?,
        conversationID: UUID,
        conversationDomain: String?
    ) async -> ZMOTRMessage?

    func isMessageMentioningSelf(
        text: Text
    ) async -> Bool

    func isMessageQuotingSelf(
        quotedMessage: ZMOTRMessage?
    ) async -> Bool

}
