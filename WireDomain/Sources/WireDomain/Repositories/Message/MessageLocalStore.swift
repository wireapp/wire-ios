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
import WireCryptobox

// sourcery: AutoMockable
/// Facilitate access to message related domain objects.
public protocol MessageLocalStoreProtocol {

    func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async
    
    /// Adds a MLS message to a given conversation
    /// - Parameters:
    ///     - decryptedMessages: A list of decrypted messages (current and buffered ones)
    ///     - mlsConversation: The MLS conversation.
    ///     - senderID: The ID of the user who sent the message.
    ///     - senderDomain: The domain of the user who sent the message.
    ///     - date: The date the message was received.

    func addMLSMessages(
        decryptedMessages: [(message: String, senderClientID: String?)],
        mlsConversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date?
    ) async
    
    /// Adds a Proteus message to a given conversation
    /// - Parameters:
    ///     - message: The message content.
    ///     - externalData: The message external data if any (used for large message payload)
    ///     - conversation: The Proteus conversation.
    ///     - senderID: The ID of the user who sent the message.
    ///     - senderDomain: The domain of the user who sent the message.
    ///     - senderClientID: The client ID of the user who sent the message.
    ///     - recipientClientID: The client ID for the user who received message.
    ///     - date: The date the message was received.
    
    func addProteusMessage(
        _ message: String,
        externalData: String?,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String,
        recipientClientID: String,
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
    
    public func addProteusMessage(
        _ message: String,
        externalData: String?,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String,
        recipientClientID: String,
        date: Date
    ) async {
        
        await createOrUpdateMessage(
            message,
            externalData: externalData,
            conversation: conversation,
            senderID: senderID,
            senderDomain: senderDomain,
            senderClientID: senderClientID,
            messageType: "conversation.otr-message-add",
            date: date
        )
        
    }
    
    public func addMLSMessages(
        decryptedMessages: [(message: String, senderClientID: String?)],
        mlsConversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date?
    ) async {
        
        for decryptedMessage in decryptedMessages {
            
            await createOrUpdateMessage(
                decryptedMessage.message,
                conversation: mlsConversation,
                senderID: senderID,
                senderDomain: senderDomain,
                senderClientID: decryptedMessage.senderClientID,
                messageType: "conversation.mls-message-add",
                date: date
            )
        }
    }

    // MARK: - Private

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
    
    /// Adds Proteus or MLS message to conversation

    private func createOrUpdateMessage(
        _ message: String,
        externalData: String? = nil,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
        messageType: String,
        date: Date?
    ) async {
        let selfUser = await userLocalStore.fetchSelfUser()

        let isSelf = await context.perform {
            conversation.isSelfConversation && senderID != selfUser.remoteIdentifier
        }
        
        let conversationID = await context.perform {
            conversation.remoteIdentifier
        }
        
        var logAttributes: LogAttributes = [
            .messageType: messageType,
            .conversationId: conversationID?.safeForLoggingDescription
        ]

        guard !isSelf else {
            return WireLogger.eventProcessing.debug(
                "Illegal sender or conversation, abort processing.",
                attributes: logAttributes
            )
        }

        let isForcedReadOnly = await conversationLocalStore.isConversationForcedReadOnly(
            conversation
        )

        guard !isForcedReadOnly else {
            return WireLogger.eventProcessing.warn(
                "Ignoring incoming message in readonly conversation.",
                attributes: logAttributes
            )
        }
        
        guard let (genericMessage, content) = await getGenericMessage(
            from: message,
            externalData: externalData,
            senderID: senderID,
            senderDomain: senderDomain,
            date: date,
            conversation: conversation,
            logAttributes: logAttributes
        ) else {
            return
        }
        
        WireLogger.eventProcessing.debug("Processing:\n\(genericMessage)")
        logAttributes[.nonce] = UUID(uuidString: genericMessage.messageID) ?? "<nil>"
        WireLogger.eventProcessing.debug("Processing message", attributes: logAttributes)

        // Update the legal hold state in the conversation
        await context.perform {
            conversation.updateSecurityLevelIfNeededAfterReceiving(
                message: genericMessage,
                timestamp: date ?? .now
            )
        }

        // Add sender to the conversation if needed
        await addParticipantIfNeeded(
            senderID: senderID,
            senderDomain: senderDomain,
            in: conversation,
            date: date
        )

        // Process the message and its content
        await processMessageContent(
            genericMessage,
            content: content,
            in: conversation,
            senderID: senderID,
            senderDomain: senderDomain,
            senderClientID: senderClientID,
            logAttributes: logAttributes,
            date: date
        )
    }
    
    private func processMessageContent(
        _ message: GenericMessage,
        content: GenericMessage.OneOf_Content,
        in conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
        logAttributes: LogAttributes,
        date: Date?
    ) async {
        await context.perform { [self] in
            switch content {
            case .lastRead where conversation.isSelfConversation:
                ZMConversation.updateConversation(
                    withLastReadFromSelfConversation: message.lastRead,
                    in: context
                )

            case .cleared where conversation.isSelfConversation:
                ZMConversation.updateConversation(
                    withClearedFromSelfConversation: message.cleared,
                    in: context
                )

            case .hidden where conversation.isSelfConversation:
                ZMMessage.remove(
                    remotelyHiddenMessage: message.hidden,
                    inContext: context
                )

            case let .dataTransfer(dataTransfer) where conversation.isSelfConversation:
                guard let trackingIdentifier = dataTransfer.trackingIdentifierData else {
                    break
                }
                
                ZMUser.selfUser(in: context).analyticsIdentifier = trackingIdentifier

            case .deleted:
                ZMMessage.remove(
                    remotelyDeletedMessage: message.deleted,
                    inConversation: conversation,
                    senderID: senderID,
                    inContext: context
                )

            case .reaction:
                ZMMessage.add(
                    reaction: message.reaction,
                    senderID: senderID,
                    conversation: conversation,
                    creationDate: date,
                    inContext: context
                )

            case .confirmation:
                break // Some logic was done here but it seems unnecessary - see legacy `ZMOTRMessage+UpdateEvent`
            case .buttonActionConfirmation:
                ZMClientMessage.updateButtonStates(
                    withConfirmation: message.buttonActionConfirmation,
                    forConversation: conversation,
                    inContext: context
                )

            case .edited:
                guard let editedMessageId = UUID(
                    uuidString: message.edited.replacingMessageID
                ) else {
                    return
                }
                
                guard let editedClientMessage = ZMClientMessage.fetch(
                    withNonce: editedMessageId,
                    for: conversation,
                    in: context
                ) else {
                    return
                }
                
                guard processMessageEdit(
                    message.edited,
                    clientMessage: editedClientMessage,
                    genericMessage: message,
                    senderID: senderID,
                    date: date ?? .now
                ) else {
                    return
                }

                editedClientMessage.updateCategoryCache()
                editedClientMessage.markAsSent()

            case .clientAction(.resetSession):
                
                let sender = ZMUser.fetchOrCreate(
                    with: senderID,
                    domain: senderDomain,
                    in: context
                )
                
                guard
                    let senderClientID = senderClientID,
                    let senderClient = UserClient.fetchUserClient(
                        withRemoteId: senderClientID,
                        forUser: sender,
                        createIfNeeded: true
                    ),
                    let timestamp = date
                else {
                    return WireLogger.eventProcessing.warn(
                        "clientAction resetSession did not create any message",
                        attributes: logAttributes
                    )
                }
                
                conversation.appendSessionResetSystemMessage(
                    user: sender,
                    client: senderClient,
                    at: timestamp
                )
                
            case .calling, .availability:
                
                break // cases not handled

            default:
                
                insertTextMessage(
                    message,
                    conversation: conversation,
                    senderID: senderID,
                    senderDomain: senderDomain,
                    senderClientID: senderClientID,
                    date: date,
                    logAttributes: logAttributes
                )
            }

        }
    }
    
    private func getGenericMessage(
        from base64Message: String,
        externalData: String?,
        senderID: UUID,
        senderDomain: String,
        date: Date?,
        conversation: ZMConversation,
        logAttributes: LogAttributes
    ) async -> (GenericMessage, GenericMessage.OneOf_Content)? {
        
        var genericMessage = GenericMessage(withBase64String: base64Message)
        
        /// If the encrypted payload is bigger than a certain size, an External Message is sent instead of a regular message.
        /// See `External` section from https://github.com/wireapp/generic-message-proto
        /// See `External messages` section from https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        if let externalData,
            case .some(.external(let external)) = genericMessage?.content {
            
            let externalData = Data(base64Encoded: externalData)
            let externalSha256 = externalData?.zmSHA256Digest()
            
            guard externalSha256 == external.sha256 else {
                WireLogger.eventProcessing.error("Invalid hash for external data: \(externalSha256 ?? Data()) != \(external.sha256)")
                return nil
            }
            
            let decryptedData = externalData?.zmDecryptPrefixedPlainTextIV(
                key: external.otrKey
            )
            
            guard let message = GenericMessage(
                withBase64String: decryptedData?.base64String()
            ) else {
                return nil
            }
            
            genericMessage = message
        }
        
        guard let genericMessage = genericMessage,
              let content = genericMessage.content else {

            await addInvalidMessage(
                conversation: conversation,
                senderID: senderID,
                senderDomain: senderDomain,
                date: date ?? .now
            )
            
            WireLogger.eventProcessing.warn(
                "Can't read protobuf, abort processing",
                attributes: logAttributes
            )
            
            return nil
        }
        
        return (genericMessage, content)
    }
    
    private func addInvalidMessage(
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date
    ) async {
        let systemMessageType: SystemMessageType = .invalid(sender: (senderID, senderDomain), date: date)
        
        let systemMessage = await createSystemMessages(
            from: systemMessageType,
            conversation: conversation
        )
    
        await addSystemMessages(
            systemMessage,
            to: conversation
        )
    }
    
    private func addParticipantIfNeeded(
        senderID: UUID,
        senderDomain: String?,
        in conversation: ZMConversation,
        date: Date?
    ) async {
        // Verifies that a sender of an update event is part of the conversation. If they are not,
        // it means that our local state is out of sync and we need to update the list of participants.
        guard let sender = try? await userLocalStore.fetchUser(
            id: senderID,
            domain: senderDomain
        ) else {
            return
        }
        
        await context.perform {
            conversation.addParticipantAndSystemMessageIfMissing(
                sender,
                date: date?.addingTimeInterval(-0.01) ?? .now
            )
        }
    }
    
    private func processMessageEdit(
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
    
    private func insertTextMessage(
        _ message: GenericMessage,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
        date: Date?,
        logAttributes: LogAttributes
    ) {
        
        func shouldAdd() -> Bool {
            if let clearedTime = conversation.clearedTimeStamp, let time = date,
               clearedTime.compare(time) != .orderedAscending {
                return false
            }
            return conversation.conversationType != .self
        }
        
        guard shouldAdd(), let nonce = UUID(uuidString: message.messageID) else {
            return WireLogger.eventProcessing.warn(
                "Dropping message because no nonce or for self conv",
                attributes: logAttributes
            )
        }
        
        let messageClass: AnyClass = GenericMessage.entityClass(for: message)
        
        var clientMessage = messageClass.fetch(
            withNonce: nonce,
            for: conversation,
            in: context,
            prefetchResult: .none
        ) as? ZMOTRMessage
        
        func isZombieObject(_ message: ZMOTRMessage?) -> Bool {
            guard let message else { return false }
            return message.isZombieObject
        }
        
        guard !isZombieObject(clientMessage)  else {
            return WireLogger.eventProcessing.warn(
                "Dropping message because zombieObject",
                attributes: logAttributes
            )
        }
        
        var isNewMessage = false
        
        if clientMessage == nil {
            isNewMessage = true
            if messageClass is ZMClientMessage.Type {
                clientMessage = ZMClientMessage(
                    nonce: nonce,
                    managedObjectContext: context
                )
                
            } else if messageClass is ZMAssetClientMessage.Type {
                clientMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: context)
            } else {
                return WireLogger.eventProcessing.warn(
                    "Dropping unknown type new message",
                    attributes: logAttributes
                )
            }
            
            clientMessage?.senderClientID = senderClientID
            clientMessage?.serverTimestamp = date
            
            let isGroup = conversation.conversationType == .group && senderID != ZMUser.selfUser(in: context).remoteIdentifier
            
            if isGroup {
                let isComposite = (message as? ConversationCompositeMessage)?.isComposite ?? false
                clientMessage?.expectsReadConfirmation = conversation.hasReadReceiptsEnabled || isComposite
            }
            
        } else if clientMessage?.senderClientID == nil || clientMessage?.senderClientID != senderClientID {
            return WireLogger.eventProcessing.warn(
                "senderClientID (\(String(describing: clientMessage?.senderClientID))) is missing or different from the update event's senderClientID (\(String(describing: senderID)))",
                attributes: logAttributes
            )
        }
        
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
        
        // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true.
        // In addition the object will still have a managedObjectContext until the context is finally saved. In this
        // case, we need to check the nonce (which would have previously been set) to avoid setting an invalid
        // relationship between the deleted object and the conversation and / or sender
        guard !isZombieObject(clientMessage) && clientMessage?.nonce != nil else {
            return WireLogger.eventProcessing.warn(
                "Dropping potential zombie message"
            )
        }
        
        guard let clientMessage else {
            return
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
    
    private func updateQuoteRelationships(message: ZMOTRMessage) {
        if let clientMessage = message as? ZMClientMessage {
            
            guard let text = clientMessage.underlyingMessage?.textData,
                  text.hasQuote else {
                return
            }
            
            clientMessage.establishRelationshipsForInsertedQuote(text.quote)

        } else if message is ZMAssetClientMessage {
            return // Asset messages don't support quotes at the moment
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
