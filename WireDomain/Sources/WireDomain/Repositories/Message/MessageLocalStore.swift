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

import CoreData
import GenericMessageProtocol
import WireDataModel
import WireLogging

public final class MessageLocalStore: MessageLocalStoreProtocol {

    enum Failure: Error {

        case invalidInsertion(reason: String)

    }

    /// When receiving a MLS/Proteus add message event, we treat them either as an `asset` client message or a `default`
    /// client message.
    enum ClientMessageType {
        case `default`
        case asset
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let assetTransferStateResolver: AssetTransferStateResolverProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext
    ) {
        self.context = context
        self.assetTransferStateResolver = AssetTransferStateResolver()
    }

    // MARK: - Public

    public func fetchMessage(
        id: UUID?,
        conversationID: UUID,
        conversationDomain: String?
    ) async -> ZMOTRMessage? {

        let conversation = await context.perform { [context] in
            ZMConversation.fetch(
                with: conversationID,
                domain: conversationDomain,
                in: context
            )
        }

        guard let conversation else { return nil }

        return await context.perform { [context] in
            ZMOTRMessage.fetch(
                withNonce: id,
                for: conversation,
                in: context
            )
        }

    }

    public func isMessageMentioningSelf(
        text: Text
    ) async -> Bool {
        let selfUser = await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }

        return await context.perform {
            text.mentions.any { $0.userID.uppercased() == selfUser.remoteIdentifier.uuidString }
        }
    }

    public func isMessageQuotingSelf(
        quotedMessage: ZMOTRMessage?
    ) async -> Bool {
        await context.perform {
            quotedMessage?.sender?.isSelfUser ?? false
        }
    }

    public func addSystemMessage(
        messageType: SystemMessageType,
        conversationID: UUID,
        conversationDomain: String?
    ) async {

        let conversation = await context.perform { [context] in
            ZMConversation.fetch(
                with: conversationID,
                domain: conversationDomain,
                in: context
            )
        }

        guard let conversation else { return }

        let systemMessages = await createSystemMessages(
            from: messageType,
            conversation: conversation
        )
        await addSystemMessages(
            systemMessages,
            to: conversation
        )
    }

    public func addPotentialGapSystemMessage() async throws {
        try await context.perform { [context] in
            guard let conversations = try context.fetch(ZMConversation.sortedFetchRequest()) as? [ZMConversation] else {
                return
            }
            for conversation in conversations {
                let offset = 0.1
                let timestamp = conversation.lastModifiedDate?.addingTimeInterval(offset) ?? Date()

                conversation.appendNewPotentialGapSystemMessage(
                    users: conversation.localParticipants,
                    timestamp: timestamp
                )
            }
        }
    }

    public func canAddMessage(
        conversation: ZMConversation,
        senderID: UUID
    ) async -> Bool {
        let selfUser = await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }

        return await context.perform {
            let isSelf = conversation.isSelfConversation && senderID != selfUser.remoteIdentifier
            return !isSelf && !conversation.isForcedReadOnly
        }
    }

    public func fetchOrCreateClientMessage(
        id: String,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date
    ) async throws -> (ZMClientMessage, isNew: Bool) {

        try await fetchOrCreateClientMessage(
            id: id,
            messageType: .default,
            conversation: conversation,
            sender: sender,
            date: date
        ) as! (ZMClientMessage, Bool)

    }

    public func fetchOrCreateAssetClientMessage(
        id: String,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date
    ) async throws -> (ZMAssetClientMessage, isNew: Bool) {

        try await fetchOrCreateClientMessage(
            id: id,
            messageType: .asset,
            conversation: conversation,
            sender: sender,
            date: date
        ) as! (ZMAssetClientMessage, Bool)

    }

    public func addClientMessage(
        _ clientMessage: ZMClientMessage,
        isNewMessage: Bool,
        genericMessage: GenericMessage,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String
    ) async {
        await context.perform { [self] in
            if isNewMessage {
                do {
                    try clientMessage.setUnderlyingMessage(genericMessage)
                    clientMessage.updateNormalizedText()
                } catch {
                    WireLogger.messaging.error("Failed to set generic message: \(error.localizedDescription)")
                    assertionFailure("Failed to set generic message: \(error.localizedDescription)")
                }
            } else {
                applyLinkPreviewUpdate(
                    clientMessage: clientMessage,
                    updatedMessage: genericMessage,
                    senderID: senderID
                )
            }

            finalizeMessageUpdate(
                message: clientMessage,
                senderID: senderID,
                senderDomain: senderDomain,
                conversation: conversation
            )
        }
    }

    public func addAssetClientMessage(
        _ assetClientMessage: ZMAssetClientMessage,
        isNewMessage: Bool,
        genericMessage: GenericMessage,
        conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String
    ) async {
        await context.perform { [self] in
            do {
                try assetClientMessage.setUnderlyingMessage(genericMessage)
            } catch {
                return assertionFailure(
                    "Failed to set generic message: \(error.localizedDescription)"
                )
            }

            // We assume received assets are V3 since backend no longer supports sending V2 assets.
            assetClientMessage.version = 3

            assetTransferStateResolver.resolveTransferState(
                assetMessage: assetClientMessage,
                genericMessage: genericMessage,
                context: context
            )

            finalizeMessageUpdate(
                message: assetClientMessage,
                senderID: senderID,
                senderDomain: senderDomain,
                conversation: conversation
            )
        }
    }

    public func addUnknownMessage(
        messageID: UUID,
        conversationID: UUID,
        conversationDomain: String?,
        senderID: UUID,
        senderDomain: String,
        payload: Data,
        date: Date
    ) async {
        await context.perform { [self] in
            guard let conversation = ZMConversation.fetch(
                with: conversationID,
                domain: conversationDomain,
                in: context
            ) else { return }

            let unknownMessage = UnknownMessage(
                nonce: messageID,
                managedObjectContext: context
            )
            unknownMessage.nonce = messageID
            unknownMessage.payload = payload
            unknownMessage.serverTimestamp = date
            finalizeMessageUpdate(
                message: unknownMessage,
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
        _ messageReaction: GenericMessageProtocol.Reaction,
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

    public func addMessageConfirmation(
        _ confirmation: GenericMessageProtocol.Confirmation,
        in conversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date
    ) async {
        await context.perform {
            _ = ZMMessageConfirmation.createMessageConfirmations(
                confirmation,
                conversation: conversation,
                senderUUID: senderID,
                senderDomain: senderDomain,
                timestamp: date
            )
        }
    }

    public func updateButtonStates(
        buttonID: String?,
        referenceMessageID: String,
        in conversation: ZMConversation,
        senderID: UUID
    ) async {
        await context.perform { [context] in

            let selfUserID = ZMUser.selfUser(in: context).remoteIdentifier
            guard senderID == selfUserID else { return }

            ZMClientMessage.updateButtonStates(
                buttonID: buttonID,
                referenceMessageID: referenceMessageID,
                for: conversation,
                in: context
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

    private func fetchOrCreateClientMessage(
        id: String,
        messageType: ClientMessageType,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date
    ) async throws -> (ZMOTRMessage, isNew: Bool) {
        try await context.perform { [self] in

            if let clearedTime = conversation.clearedTimeStamp, clearedTime.compare(date) != .orderedAscending {
                throw Failure.invalidInsertion(reason: "message is older than cleared time")
            }

            guard conversation.conversationType != .`self` else {
                throw Failure.invalidInsertion(reason: "message cannot be sent to self")
            }

            guard let nonce = UUID(uuidString: id) else {
                throw Failure.invalidInsertion(reason: "invalid nonce")
            }

            let clientMessage = messageType == .asset ?
                ZMAssetClientMessage.fetch(
                    withNonce: nonce,
                    for: conversation,
                    in: context
                ) :
                ZMClientMessage.fetch(
                    withNonce: nonce,
                    for: conversation,
                    in: context
                )

            if let clientMessage {
                return (clientMessage, false)
            } else {
                let newClientMessage = messageType == .asset ?
                    ZMAssetClientMessage(
                        nonce: nonce,
                        managedObjectContext: context
                    ) :
                    ZMClientMessage(
                        nonce: nonce,
                        managedObjectContext: context
                    )

                setupNewClientMessage(
                    newClientMessage,
                    conversation: conversation,
                    senderID: sender.id,
                    clientID: sender.clientID,
                    date: date
                )

                return (newClientMessage, true)
            }
        }
    }

    private func setupNewClientMessage(
        _ message: ZMOTRMessage,
        conversation: ZMConversation,
        senderID: UUID,
        clientID: String?,
        date: Date
    ) {
        message.senderClientID = clientID
        message.serverTimestamp = date
        let selfUserID = ZMUser.selfUser(in: context).remoteIdentifier

        if conversation.conversationType == .group, senderID != selfUserID {
            let isComposite = (message as? ConversationCompositeMessage)?.isComposite ?? false
            message.expectsReadConfirmation = conversation.hasReadReceiptsEnabled || isComposite
        }
    }

    private func finalizeMessageUpdate(
        message: ZMOTRMessage,
        senderID: UUID,
        senderDomain: String,
        conversation: ZMConversation
    ) {
        let sender = ZMUser.fetchOrCreate(
            with: senderID,
            domain: senderDomain,
            in: context
        )

        message.visibleInConversation = conversation
        message.sender = sender
        updateQuoteRelationships(message: message)
        conversation.updateTimestampsAfterUpdatingMessage(message)
        message.unarchiveIfNeeded(conversation)
        message.updateCategoryCache()
        message.markAsSent()
    }

    private func createSystemMessages(
        from messageType: SystemMessageType,
        conversation: ZMConversation
    ) async -> Set<ZMSystemMessage> {
        switch messageType {
        case let .federationTermination(domains, date):
            let selfUser = await fetchSelfUser()

            let systemMessage = await createSystemMessage(
                messageType: .domainsStoppedFederating,
                sender: selfUser,
                timestamp: date,
                domains: domains
            )

            return [systemMessage]

        case let .participantsRemovedAnonymously(participants, date):

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

        case let .participantsRemoved(participants, sender, date):

            let removedUsers = await context.perform {
                participants.compactMap { id, domain in
                    let existing = conversation.localParticipants

                    return existing.first(where: {
                        $0.remoteIdentifier == id && $0.domain == domain
                    })
                }
            }

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .participantsRemoved,
                sender: sender,
                users: Set(removedUsers),
                timestamp: date
            )

            return [systemMessage]

        case let .participantsAdded(participants, sender, date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let newUsers = await context.perform { [context] in
                participants.map {
                    ZMUser.fetchOrCreate(
                        with: $0.id,
                        domain: $0.domain,
                        in: context
                    )
                }
            }

            let systemMessage = await createSystemMessage(
                messageType: .participantsAdded,
                sender: sender,
                users: Set(newUsers),
                timestamp: date
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

        case let .mlsMigrationMLSNotSupportedForOtherUser(otherUser):

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

        case let .teamMemberRemoved(member, date):

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

        case let .newConversationCreated(date):

            let selfUser = await fetchSelfUser()

            let (creator, localParticipants, userDefinedName) = await context.perform {
                (
                    conversation.creator,
                    conversation.localParticipants,
                    conversation.userDefinedName
                )
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
                    !$0.isAppOrBot && $0.membership == nil
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

        case let .mlsMigrationStarted(sender, date):

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

        case let .mlsMigrationPotentialGap(sender, date):

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

        case let .mlsMigrationFinalized(sender, date):

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

        case let .receiptModeIsOn(date):

            let creator = await context.perform {
                conversation.creator
            }

            let systemMessage = await createSystemMessage(
                messageType: .readReceiptsOn,
                sender: creator,
                timestamp: date
            )

            return [systemMessage]

        case let .unknownMessageContentTypeReceived(sender, date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .unknownMessageContentTypeReceived,
                sender: sender,
                timestamp: date
            )

            return [systemMessage]

        case let .invalid(sender, date):
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

        case let .decryptionFailed(sender, senderClientID, remoteIdentityChanged, date):
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

            let type = remoteIdentityChanged ? ZMSystemMessageType
                .decryptionFailed_RemoteIdentityChanged : ZMSystemMessageType.decryptionFailed

            let clients = senderClient.flatMap { [$0] } ?? Set<UserClient>()

            let systemMessage = await createSystemMessage(
                messageType: type,
                sender: sender,
                clients: clients,
                timestamp: date
            )

            return [systemMessage]

        case let .sessionReset(sender, senderClientID, date):
            let sender = await context.perform { [context] in
                ZMUser.fetchOrCreate(
                    with: sender.id,
                    domain: sender.domain,
                    in: context
                )
            }

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

        case let .messageTimerUpdate(sender, date, timeoutValue):

            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .messageTimerUpdate,
                sender: sender,
                users: [sender],
                timestamp: date,
                messageTimer: timeoutValue
            )

            return [systemMessage]

        case let .conversationNameChanged(newName, sender, date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .conversationNameChanged,
                sender: sender,
                timestamp: date
            )

            await context.perform {
                systemMessage.text = newName
                systemMessage.visibleInConversation = conversation
                conversation.updateTimestampsAfterUpdatingMessage(systemMessage)
            }

            return [systemMessage]

        case let .readReceiptsStatus(isEnabled, sender, date):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: isEnabled ? .readReceiptsEnabled : .readReceiptsDisabled,
                sender: sender,
                timestamp: date
            )

            await context.perform {
                let isArchived = conversation.isArchived
                let mutedMessageTypes = conversation.mutedMessageTypes

                if isArchived, mutedMessageTypes == .none {
                    conversation.isArchived = false
                }
            }

            return [systemMessage]

        case let .channelHistoryDepthModified(sender):
            guard let sender = await fetchUser(
                id: sender.id,
                domain: sender.domain
            ) else {
                return []
            }

            let systemMessage = await createSystemMessage(
                messageType: .channelHistoryDepthModified,
                sender: sender,
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
        text: String? = nil,
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
            systemMessage.text = text

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
        await context.perform { [context] in
            ZMUser.fetch(
                with: id,
                domain: domain,
                in: context
            )
        }
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
            let messageEditContent = messageEdit.content,
            senderID == clientMessage.sender?.remoteIdentifier
        else { return false }

        let genericMessage: GenericMessage
        switch messageEditContent {

        case let .text(newText):
            guard let originalText = clientMessage.underlyingMessage?.textData else { return false }
            genericMessage = GenericMessage(
                content: originalText.applyEdit(from: newText),
                nonce: messageNonce
            )

        case let .composite(newComposite):
            guard clientMessage.underlyingMessage?.compositeData != nil else { return false }
            genericMessage = GenericMessage(
                content: newComposite,
                nonce: messageNonce
            )

        case let .multipart(multipart):
            genericMessage = GenericMessage(
                content: multipart,
                nonce: messageNonce
            )
        }

        do {
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

}
