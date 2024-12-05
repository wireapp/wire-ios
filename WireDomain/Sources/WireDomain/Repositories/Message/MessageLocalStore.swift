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
import WireCryptobox
import WireDataModel

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

    /// Adds a message text to a given conversation.
    /// - Parameters:
    ///     - message: The message to add.
    ///     - conversation: The conversation to add the message text to.
    ///     - senderID: The message sender id.
    ///     - senderDomain: The message sender domain.
    ///     - senderClientID: The sender client id.
    ///     - date: The date the message was created.
    ///     - logAttributes: Attributes to add to the log.

    func addTextMessage(
        _ message: GenericMessage,
        in conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
        date: Date,
        logAttributes: LogAttributes
    ) async

    /// Checks whether a message can be added to the conversation.
    /// - Parameters:
    ///     - conversation: The conversation to add the message to.
    ///     - senderID: The message sender id.
    ///     - logAttributes: Attributes to add to the log.

    func canAddMessage(
        conversation: ZMConversation,
        senderID: UUID,
        logAttributes: LogAttributes
    ) async -> Bool

    /// Deletes a given message from all of the self user's devices.
    /// - Parameters:
    ///     - hiddenMessage: The hidden message protobuf object.
    ///     - conversation: The related conversation.
    ///
    /// "Delete for me" will locally delete the message, and tell all other devices of this user to delete the message in a similar fashion.
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
    /// "Delete for everyone" will recall the message. The message is deleted locally, and all other participants devices in the conversation are requested to delete the message.
    /// In the optimal case, these devices will delete the message and replace it with a visible "delete message" placeholder.

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
        _ messageReaction: WireProtos.Reaction,
        in conversation: ZMConversation,
        senderID: UUID,
        date: Date
    ) async

    /// Updates button states.
    /// - Parameters:
    ///     - buttonActionConfirmation: The button action confirmation protobuf object.
    ///     - conversation: The related conversation.
    ///
    /// When someone has clicked on a button, to confirm to them that the answer has been accepted.

    func updateButtonStates(
        _ buttonActionConfirmation: ButtonActionConfirmation,
        in conversation: ZMConversation
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

}

public final class MessageLocalStore: MessageLocalStoreProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.context = context
        self.conversationLocalStore = conversationLocalStore
        self.userLocalStore = userLocalStore
    }

    // MARK: - Public

    public func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async {
        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID,
            domain: conversationDomain
        ) else { return }

        let systemMessages = await createSystemMessages(
            from: messageType,
            conversation: conversation
        )

        await addSystemMessages(
            systemMessages,
            to: conversation
        )
    }

    public func canAddMessage(
        conversation: ZMConversation,
        senderID: UUID,
        logAttributes: LogAttributes
    ) async -> Bool {
        let selfUser = await userLocalStore.fetchSelfUser()

        return await context.perform {
            let isSelf = conversation.isSelfConversation && senderID != selfUser.remoteIdentifier

            guard !isSelf else {
                WireLogger.eventProcessing.debug(
                    "Illegal sender or conversation, abort processing.",
                    attributes: logAttributes
                )

                return false
            }

            guard !conversation.isForcedReadOnly else {
                WireLogger.eventProcessing.warn(
                    "Ignoring incoming message in readonly conversation.",
                    attributes: logAttributes
                )

                return false
            }

            return true
        }
    }

    public func addTextMessage(
        _ message: GenericMessage,
        in conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
        date: Date,
        logAttributes: LogAttributes
    ) async {
        await context.perform { [self] in
            guard shouldAddMessage(to: conversation, date: date),
                  let nonce = UUID(uuidString: message.messageID)
            else {
                return WireLogger.eventProcessing.warn(
                    "Dropping message because no nonce or for self conv",
                    attributes: logAttributes
                )
            }

            let messageClass: AnyClass = GenericMessage.entityClass(for: message)
            var clientMessage = fetchExistingMessage(
                nonce: nonce,
                conversation: conversation,
                messageClass: messageClass
            )

            guard !isZombieObject(clientMessage) else {
                return WireLogger.eventProcessing.warn(
                    "Dropping message because zombieObject",
                    attributes: logAttributes
                )
            }

            let isNewMessage = clientMessage == nil
            clientMessage = clientMessage ?? createNewMessage(
                nonce: nonce,
                messageClass: messageClass,
                genericMessage: message,
                date: date,
                senderID: senderID,
                senderClientID: senderClientID,
                conversation: conversation,
                logAttributes: logAttributes
            )

            if let assetClientMessage = clientMessage as? ZMAssetClientMessage {
                updateAssetClientMessage(
                    assetClientMessage,
                    genericMessage: message,
                    isNewMessage: isNewMessage
                )
            } else if let clientMessage = clientMessage as? ZMClientMessage {
                updateClientMessage(
                    clientMessage,
                    genericMessage: message,
                    senderID: senderID,
                    isNewMessage: isNewMessage
                )
            }

            guard let clientMessage else { return }

            finalizeMessageUpdate(
                clientMessage: clientMessage,
                message: message,
                senderID: senderID,
                senderDomain: senderDomain,
                conversation: conversation
            )
        }
    }

    public func deleteMessageForSelf(
        _ hiddenMessage: MessageHide,
        in conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            guard conversation.isSelfConversation else {
                return
            }

            ZMMessage.remove(
                remotelyHiddenMessage: hiddenMessage,
                inContext: context
            )
        }
    }

    public func deleteMessageForEveryone(
        _ deletedMessage: MessageDelete,
        in conversation: ZMConversation,
        senderID: UUID
    ) async {
        await context.perform { [context] in
            ZMMessage.remove(
                remotelyDeletedMessage: deletedMessage,
                inConversation: conversation,
                senderID: senderID,
                inContext: context
            )
        }
    }

    public func addMessageReaction(
        _ messageReaction: WireProtos.Reaction,
        in conversation: ZMConversation,
        senderID: UUID,
        date: Date
    ) async {
        await context.perform { [context] in
            ZMMessage.add(
                reaction: messageReaction,
                senderID: senderID,
                conversation: conversation,
                creationDate: date,
                inContext: context
            )
        }
    }

    public func updateButtonStates(
        _ buttonActionConfirmation: ButtonActionConfirmation,
        in conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            ZMClientMessage.updateButtonStates(
                withConfirmation: buttonActionConfirmation,
                forConversation: conversation,
                inContext: context
            )
        }
    }

    public func editMessage(
        _ messageEdit: MessageEdit,
        in conversation: ZMConversation,
        senderID: UUID,
        genericMessage: GenericMessage,
        date: Date
    ) async {
        guard let editedMessageID = UUID(
            uuidString: messageEdit.replacingMessageID
        ) else {
            return
        }

        await context.perform { [self] in
            guard let editedClientMessage = ZMClientMessage.fetch(
                withNonce: editedMessageID,
                for: conversation,
                in: context
            ) else {
                return
            }

            guard editMessage(
                messageEdit,
                clientMessage: editedClientMessage,
                genericMessage: genericMessage,
                senderID: senderID,
                date: date
            ) else {
                return
            }

            editedClientMessage.updateCategoryCache()
            editedClientMessage.markAsSent()
        }
    }

    // MARK: - Private

    private func shouldAddMessage(to conversation: ZMConversation, date: Date) -> Bool {
        if let clearedTime = conversation.clearedTimeStamp,
           clearedTime.compare(date) != .orderedAscending {
            return false
        }
        return conversation.conversationType != .self
    }

    private func createNewMessage(
        nonce: UUID,
        messageClass: AnyClass,
        genericMessage: GenericMessage,
        date: Date,
        senderID: UUID,
        senderClientID: String?,
        conversation: ZMConversation,
        logAttributes: LogAttributes
    ) -> ZMOTRMessage? {
        guard let newMessage = instantiateNewMessage(messageClass: messageClass, nonce: nonce) else {
            WireLogger.eventProcessing.warn(
                "Dropping unknown type new message",
                attributes: logAttributes
            )
            return nil
        }

        newMessage.senderClientID = senderClientID
        newMessage.serverTimestamp = date

        if conversation.conversationType == .group,
           senderID != ZMUser.selfUser(in: context).remoteIdentifier {
            let isComposite = (genericMessage as? ConversationCompositeMessage)?.isComposite ?? false
            newMessage.expectsReadConfirmation = conversation.hasReadReceiptsEnabled || isComposite
        }

        return newMessage
    }

    private func instantiateNewMessage(messageClass: AnyClass, nonce: UUID) -> ZMOTRMessage? {
        if messageClass is ZMClientMessage.Type {
            return ZMClientMessage(nonce: nonce, managedObjectContext: context)
        } else if messageClass is ZMAssetClientMessage.Type {
            return ZMAssetClientMessage(nonce: nonce, managedObjectContext: context)
        }
        return nil
    }

    private func fetchExistingMessage(
        nonce: UUID,
        conversation: ZMConversation,
        messageClass: AnyClass
    ) -> ZMOTRMessage? {
        messageClass.fetch(
            withNonce: nonce,
            for: conversation,
            in: context,
            prefetchResult: .none
        ) as? ZMOTRMessage
    }

    private func isZombieObject(_ message: ZMOTRMessage?) -> Bool {
        guard let message else { return false }
        return message.isZombieObject
    }

    private func finalizeMessageUpdate(
        clientMessage: ZMOTRMessage,
        message: GenericMessage,
        senderID: UUID,
        senderDomain: String,
        conversation: ZMConversation
    ) {
        guard !isZombieObject(clientMessage), clientMessage.nonce != nil else {
            return WireLogger.eventProcessing.warn(
                "Dropping potential zombie message"
            )
        }

        let sender = ZMUser.fetchOrCreate(
            with: senderID,
            domain: senderDomain,
            in: context
        )

        clientMessage.visibleInConversation = conversation
        clientMessage.sender = sender
        updateQuoteRelationships(message: clientMessage)
        conversation.updateTimestampsAfterUpdatingMessage(clientMessage)
        clientMessage.unarchiveIfNeeded(conversation)
        clientMessage.updateCategoryCache()
        clientMessage.markAsSent()
    }

    private func createSystemMessages(
        from messageType: SystemMessageType,
        conversation: ZMConversation
    ) async -> Set<ZMSystemMessage> {
        switch messageType {
        case .federationTermination(let domains, let date):
            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .domainsStoppedFederating,
                sender: selfUser,
                timestamp: date,
                domains: domains
            )

            return [systemMessage]

        case .participantsRemovedAnonymously(let participants, let date):

            let removedUsers = await context.perform {
                participants.compactMap { id, domain in
                    let existing = conversation.localParticipants

                    return existing.first(where: {
                        $0.remoteIdentifier == id && $0.domain == domain
                    })
                }
            }

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .participantsRemoved,
                sender: selfUser,
                users: Set(removedUsers),
                timestamp: date,
                removedReason: .federationTermination
            )

            return [systemMessage]

        case .mlsMigrationMLSNotSupportedForSelfUser:

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .mlsNotSupportedSelfUser,
                sender: selfUser,
                users: Set([selfUser])
            )

            return [systemMessage]

        case .mlsMigrationMLSNotSupportedForOtherUser(let otherUser):

            guard let otherUser = await fetchUser(
                id: otherUser.id,
                domain: otherUser.domain
            ) else { return [] }

            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .mlsNotSupportedOtherUser,
                sender: selfUser,
                users: Set([otherUser])
            )

            return [systemMessage]

        case .teamMemberRemoved(let member, let date):

            guard let removedMember = await fetchUser(
                id: member.id,
                domain: member.domain
            ) else { return [] }

            let systemMessage = await createSystemMessage(
                messageType: .teamMemberLeave,
                sender: removedMember,
                users: Set([removedMember]),
                timestamp: date
            )

            return [systemMessage]

        case .participantRemoved(let participant, let sender, let date):

            guard let removedParticipant = await fetchUser(
                id: participant.id,
                domain: participant.domain
            ) else { return [] }

            let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            )

            let systemMessage = await createSystemMessage(
                messageType: .participantsRemoved,
                sender: sender ?? removedParticipant,
                users: Set([removedParticipant]),
                timestamp: date
            )

            return [systemMessage]

        case .newConversationCreated(let date):

            let selfUser = await fetchSelfUser()

            let (creator, localParticipants, userDefinedName) = await context.perform {
                (conversation.creator,
                 conversation.localParticipants,
                 conversation.userDefinedName)
            }

            let newConversationMessage = await createSystemMessage(
                messageType: .newConversation,
                sender: creator,
                users: localParticipants,
                timestamp: date
            )

            await context.perform {
                newConversationMessage.text = userDefinedName

                guard let selfUserTeam = selfUser.team,
                      conversation.team == selfUserTeam else { return }

                let members = selfUserTeam.members.compactMap(\.user)
                let guests = localParticipants.filter {
                    !$0.isServiceUser && $0.membership == nil
                }

                newConversationMessage.allTeamUsersAdded = localParticipants.isSuperset(of: members)
                newConversationMessage.numberOfGuestsAdded = Int16(guests.count)
            }

            let hasReadReceiptsEnabled = await context.perform {
                conversation.hasReadReceiptsEnabled
            }

            guard hasReadReceiptsEnabled else {
                return [newConversationMessage]
            }

            let nextNearestTimestamp = Date(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate.nextUp)

            let receiptModeIsOnMessage = await createSystemMessages(
                from: .receiptModeIsOn(date: nextNearestTimestamp),
                conversation: conversation
            )

            let systemMessages = [newConversationMessage] + receiptModeIsOnMessage

            return Set(systemMessages)

        case .mlsMigrationStarted(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationStarted,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case .mlsMigrationPotentialGap(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationPotentialGap,
                sender: sender,
                timestamp: date
            )

            let previousLastMessage = await context.perform {
                conversation.lastMessage
            }

            await context.perform { [context] in
                let lastMessage = previousLastMessage as? ZMSystemMessage
                let isPotentialGapMigration = lastMessage?.systemMessageType == .mlsMigrationPotentialGap
                let lastMessageTimestamp = lastMessage?.serverTimestamp

                if let lastMessage, isPotentialGapMigration {
                    if let lastMessageTimestamp, lastMessageTimestamp <= date {
                        context.delete(lastMessage)
                    }
                }
            }

            return [systemMessage]

        case .mlsMigrationFinalized(let sender, let date):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .mlsMigrationFinalized,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case .receiptModeIsOn(let date):

            let creator = await context.perform {
                conversation.creator
            }

            let systemMessage = await createSystemMessage(
                messageType: .readReceiptsOn,
                sender: creator,
                timestamp: date
            )

            return [systemMessage]

        case .invalid(let sender, let date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .invalid,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case .decryptionFailed(let sender, let senderClientID, let errorCode, let date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let senderClient = await context.perform {
                sender.clients.first(where: {
                    $0.remoteIdentifier == senderClientID
                })
            }

            let type = (UInt32(errorCode) == CBOX_REMOTE_IDENTITY_CHANGED.rawValue) ? ZMSystemMessageType.decryptionFailed_RemoteIdentityChanged : ZMSystemMessageType.decryptionFailed

            let clients = senderClient.flatMap { [$0] } ?? Set<UserClient>()

            let systemMessage = await createSystemMessage(
                messageType: type,
                sender: sender,
                clients: clients,
                timestamp: date
            )

            return [systemMessage]

        case .sessionReset(let sender, let senderClientID, let date):
            let sender = await userLocalStore.fetchOrCreateUser(
                id: sender.id,
                domain: sender.domain
            )

            let client = await context.perform {
                UserClient.fetchUserClient(
                    withRemoteId: senderClientID,
                    forUser: sender,
                    createIfNeeded: true
                )
            }

            guard let client else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .sessionReset,
                sender: sender,
                clients: [client],
                timestamp: date
            )

            return [systemMessage]
        }
    }

    private func createSystemMessage(
        messageType: ZMSystemMessageType,
        sender: ZMUser,
        users: Set<ZMUser>? = nil,
        addedUsers: Set<ZMUser> = Set(),
        clients: Set<UserClient>? = nil,
        timestamp: Date = .now,
        duration: TimeInterval? = nil,
        messageTimer: Double? = nil,
        relevantForStatus: Bool = true,
        removedReason: ZMParticipantsRemovedReason = .none,
        domains: [String]? = nil
    ) async -> ZMSystemMessage {
        await context.perform { [context] in
            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: context)
            systemMessage.systemMessageType = messageType
            systemMessage.sender = sender
            systemMessage.users = users ?? Set()
            systemMessage.addedUsers = addedUsers
            systemMessage.clients = clients ?? Set()
            systemMessage.serverTimestamp = timestamp

            if let duration {
                systemMessage.duration = duration
            }

            if let messageTimer {
                systemMessage.messageTimer = NSNumber(value: messageTimer)
            }

            systemMessage.relevantForConversationStatus = relevantForStatus
            systemMessage.participantsRemovedReason = removedReason
            systemMessage.domains = domains

            return systemMessage
        }
    }

    private func addSystemMessages(
        _ messages: Set<ZMSystemMessage>,
        to conversation: ZMConversation
    ) async {
        await context.perform {
            for message in messages {
                conversation.append(message)
            }
        }
    }

    private func fetchUser(
        id: UUID,
        domain: String?
    ) async -> ZMUser? {
        try? await userLocalStore.fetchUser(
            id: id,
            domain: domain
        )
    }

    private func fetchSelfUser() async -> ZMUser {
        await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }
    }

    private func editMessage(
        _ messageEdit: MessageEdit,
        clientMessage: ZMClientMessage,
        genericMessage: GenericMessage,
        senderID: UUID,
        date: Date
    ) -> Bool {
        guard
            let messageNonce = UUID(uuidString: genericMessage.messageID),
            let originalText = clientMessage.underlyingMessage?.textData,
            case .text? = messageEdit.content,
            senderID == clientMessage.sender?.remoteIdentifier
        else {
            return false
        }

        do {
            let genericMessage = GenericMessage(
                content: originalText.applyEdit(from: messageEdit.text),
                nonce: messageNonce
            )
            try clientMessage.setUnderlyingMessage(genericMessage)
        } catch {
            WireLogger.messageProcessing.warn(
                "Failed to process message edit. Reason: \(error.localizedDescription)"
            )
            return false
        }

        clientMessage.updateNormalizedText()
        clientMessage.nonce = messageNonce
        clientMessage.updatedTimestamp = date
        clientMessage.reactions.removeAll()
        clientMessage.linkAttachments = nil

        return true
    }

    private func updateQuoteRelationships(message: ZMOTRMessage) {
        if let clientMessage = message as? ZMClientMessage {
            guard let text = clientMessage.underlyingMessage?.textData,
                  text.hasQuote
            else {
                return
            }

            clientMessage.establishRelationshipsForInsertedQuote(text.quote)

        } else if message is ZMAssetClientMessage {
            // Asset messages don't support quotes at the moment
            return
        }
    }

    private func updateClientMessage(
        _ clientMessage: ZMClientMessage,
        genericMessage: GenericMessage,
        senderID: UUID,
        isNewMessage: Bool
    ) {
        guard isNewMessage else {
            applyLinkPreviewUpdate(
                clientMessage: clientMessage,
                updatedMessage: genericMessage,
                senderID: senderID
            )
            return
        }

        do {
            try clientMessage.setUnderlyingMessage(genericMessage)
            clientMessage.updateNormalizedText()
        } catch {
            assertionFailure("Failed to set generic message: \(error.localizedDescription)")
        }
    }

    private func applyLinkPreviewUpdate(
        clientMessage: ZMClientMessage,
        updatedMessage: GenericMessage,
        senderID: UUID
    ) {
        guard
            let nonce = clientMessage.nonce,
            let originalText = clientMessage.underlyingMessage?.textData,
            let updatedText = updatedMessage.textData,
            senderID == clientMessage.sender?.remoteIdentifier,
            originalText.content == updatedText.content
        else {
            return
        }

        let timeout = clientMessage.deletionTimeout > 0 ? clientMessage.deletionTimeout : nil
        let message = GenericMessage(
            content: originalText.updateLinkPreview(from: updatedText),
            nonce: nonce,
            expiresAfterTimeInterval: timeout
        )

        do {
            try clientMessage.setUnderlyingMessage(message)
        } catch {
            assertionFailure("Failed to set generic message: \(error.localizedDescription)")
        }
    }

    private func updateAssetClientMessage(
        _ assetClientMessage: ZMAssetClientMessage,
        genericMessage: GenericMessage,
        isNewMessage: Bool
    ) {
        do {
            try assetClientMessage.setUnderlyingMessage(genericMessage)
        } catch {
            return assertionFailure(
                "Failed to set generic message: \(error.localizedDescription)"
            )
        }

        // We assume received assets are V3 since backend no longer supports sending V2 assets.
        assetClientMessage.version = 3

        guard
            let assetData = genericMessage.assetData,
            let status = assetData.status
        else {
            return
        }

        switch status {
        case .uploaded(let data) where data.hasAssetID:
            assetClientMessage.updateTransferState(
                .uploaded,
                synchronize: false
            )

        case .notUploaded where assetClientMessage.transferState != .uploaded:
            switch assetData.notUploaded {
            case .cancelled:
                context.delete(assetClientMessage)
            case .failed:
                assetClientMessage.updateTransferState(
                    .uploadingFailed,
                    synchronize: false
                )
            }

        default:
            break
        }
    }

}
