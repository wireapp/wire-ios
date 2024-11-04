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

import WireAPI
import WireDataModel

/// An extension that encapsulates storage operations related to MLS.

extension ConversationLocalStore {
    
    // MARK: - Public
    
    public func addMLSMessage(
        _ encryptedMessage: String,
        mlsGroupID: MLSGroupID,
        mlsConversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        subconversation: String?,
        date: Date?
    ) async {
        
        let decryptionResults = await decryptMLSMessage(
            message: encryptedMessage,
            mlsGroupID: mlsGroupID,
            subconversation: subconversation
        )
        
        await processMLSMessageDecryptionResults(
            decryptionResults,
            mlsConversation: mlsConversation,
            senderID: senderID,
            senderDomain: senderDomain,
            date: date
        )
        
    }
    
    // MARK: - Private
    
    private func decryptMLSMessage(
        message: String,
        mlsGroupID: MLSGroupID,
        subconversation: String?
    ) async -> [MLSDecryptResult] {
        do {
            let subconvType = subconversation != nil ? SubgroupType(rawValue: subconversation!) : nil

            let results = try await decryptionService.decrypt(
                message: message,
                for: mlsGroupID,
                subconversationType: subconvType
            )

            if results.isEmpty {
                WireLogger.mls.info(
                    "successfully decrypted mls message but no result was returned"
                )

                return []
            }

            return results

        } catch {
            WireLogger.mls.warn(
                "failed to decrypt mls message: \(String(describing: error))"
            )

            return []
        }
    }
    
    private func processMLSMessageDecryptionResults(
        _ results: [MLSDecryptResult],
        mlsConversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date?
    ) async {
        for result in results {
            switch result {
            case .message(let decryptedData, let senderClientID):
                let mlsDecryptedMessage = decryptedData.base64EncodedString()
                
                await createOrUpdateMessage(
                    mlsDecryptedMessage,
                    conversation: mlsConversation,
                    senderID: senderID,
                    senderDomain: senderDomain,
                    senderClientID: senderClientID,
                    date: date
                )

            case .proposal(let commitDelay):
                await commitPendingProposals(
                    conversation: mlsConversation,
                    commitDelay: commitDelay,
                    date: date
                )
            }
        }
        
        await context.perform { [context] in
            context.processPendingChanges()
        }
    }
    
    private func createOrUpdateMessage(
        _ message: String,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        senderClientID: String?,
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
            .messageType: "conversation.mls-message-add",
            .conversationId: conversationID?.safeForLoggingDescription
        ]

        guard !isSelf else {
            return WireLogger.eventProcessing.debug(
                "Illegal sender or conversation, abort processing.",
                attributes: logAttributes
            )
        }

        let isForcedReadOnly = await isConversationForcedReadOnly(conversation)

        guard !isForcedReadOnly else {
            return WireLogger.eventProcessing.warn(
                "Ignoring incoming message in readonly conversation.",
                attributes: logAttributes
            )
        }
        
        guard let (genericMessage, content) = await getGenericMessage(
            from: message,
            senderID: senderID,
            senderDomain: senderDomain,
            date: date,
            conversation: conversation,
            logAttributes: logAttributes
        ) else { return }
        
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
    
    private func commitPendingProposals(
        conversation: ZMConversation,
        commitDelay: UInt64,
        date: Date?
    ) async {
        let scheduledDate = (date ?? Date.now) + TimeInterval(commitDelay)
        
        await context.perform {
            conversation.commitPendingProposalDate = scheduledDate
        }
        
        mlsService.commitPendingProposalsIfNeeded()
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
        senderID: UUID,
        senderDomain: String,
        date: Date?,
        conversation: ZMConversation,
        logAttributes: LogAttributes
    ) async -> (GenericMessage, GenericMessage.OneOf_Content)? {
        guard let genericMessage = GenericMessage(withBase64String: base64Message),
              let content = genericMessage.content else {
            
            if let sender = try? await userLocalStore.fetchUser(
                with: senderID,
                domain: senderDomain
            ) {
                let systemMessage = SystemMessage(
                    type: .invalid,
                    sender: sender,
                    timestamp: date ?? .now
                )
                
                await addSystemMessage(
                    systemMessage,
                    to: conversation
                )
            }
            
            WireLogger.eventProcessing.warn(
                "Can't read protobuf, abort processing",
                attributes: logAttributes
            )
            
            return nil
        }
        
        return (genericMessage, content)
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
            with: senderID,
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
    
    // MARK: - Update message protocols

    func assignMessageProtocol(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) {
        guard let newMessageProtocol = remoteConversation.messageProtocol else {
            eventProcessingLogger.warn(
                "message protocol is missing"
            )
            return
        }

        localConversation.messageProtocol = newMessageProtocol.toDomainModel()
    }

    func updateMessageProtocol(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) {
        guard let newMessageProtocol = remoteConversation.messageProtocol else {
            eventProcessingLogger.warn(
                "message protocol is missing"
            )
            return
        }

        let sender = ZMUser.selfUser(in: context)

        switch localConversation.messageProtocol {
        case .proteus:
            switch newMessageProtocol {
            case .proteus:
                break /// no update, ignore
            case .mixed:
                localConversation.appendMLSMigrationStartedSystemMessage(sender: sender, at: .now)
                localConversation.messageProtocol = newMessageProtocol.toDomainModel()

            case .mls:
                let date = localConversation.lastModifiedDate ?? .now
                localConversation.appendMLSMigrationPotentialGapSystemMessage(sender: sender, at: date)
                localConversation.messageProtocol = newMessageProtocol.toDomainModel()
            }

        case .mixed:
            switch newMessageProtocol {
            case .proteus:
                updateEventLogger.warn(
                    "update message protocol from \(localConversation.messageProtocol) to \(newMessageProtocol) is not allowed, ignore event!"
                )

            case .mixed:
                break /// no update, ignore
            case .mls:
                localConversation.appendMLSMigrationFinalizedSystemMessage(sender: sender, at: .now)
                localConversation.messageProtocol = newMessageProtocol.toDomainModel()
            }

        case .mls:
            switch newMessageProtocol {
            case .proteus, .mixed:
                updateEventLogger.warn(
                    "update message protocol from '\(localConversation.messageProtocol)' to '\(newMessageProtocol)' is not allowed, ignore event!"
                )

            case .mls:
                break
            }
        }
    }

    // MARK: - Self MLS Conversation

    func createOrJoinSelfConversation(
        from localConversation: ZMConversation
    ) async throws {
        let (groupID, mlsService, hasRegisteredMLSClient) = await context.perform { [context] in
            (
                localConversation.mlsGroupID,
                context.mlsService,
                ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true
            )
        }

        guard let groupID, let mlsService, hasRegisteredMLSClient else {
            mlsLogger.warn(
                "no mlsService or not registered mls client to createOrJoinSelfConversation"
            )
            return
        }

        mlsLogger.debug(
            "createOrJoinSelfConversation for \(groupID.safeForLoggingDescription); conv payload: \(String(describing: self))"
        )

        if await context.perform({ localConversation.epoch <= 0 }) {
            let ciphersuite = try await mlsService.createSelfGroup(for: groupID)
            await context.perform { localConversation.ciphersuite = ciphersuite }
        } else if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }
    }
}
