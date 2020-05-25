//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "event-processing")

extension ZMOTRMessage {
    @objc static func createOrUpdate(fromUpdateEvent updateEvent: ZMUpdateEvent,
                                     inManagedObjectContext moc: NSManagedObjectContext,
                                     prefetchResult: ZMFetchRequestBatchResult) -> ZMOTRMessage? {
        let selfUser = ZMUser.selfUser(in: moc)

        guard
            let senderID = updateEvent.senderUUID(),
            let conversation = self.conversation(for: updateEvent, in: moc, prefetchResult: prefetchResult),
            !isSelf(conversation: conversation, andIsSenderID: senderID, differentFromSelfUserID: selfUser.remoteIdentifier)
        else {
            zmLog.debug("Illegal sender or conversation, abort processing.")
            return nil
        }
        
        guard let message = ZMGenericMessage(from: updateEvent) else {
            zmLog.debug("Can't read protobuf, abort processing:\n\(updateEvent.payload)")
            appendInvalidSystemMessage(forUpdateEvent: updateEvent, toConversation: conversation, inContext: moc)
            return nil
        }
        zmLog.debug("Processing:\n\(message.debugDescription)")
        
        // Update the legal hold state in the conversation
        conversation.updateSecurityLevelIfNeededAfterReceiving(message: message, timestamp: updateEvent.timeStamp() ?? Date())
        
        if !message.knownMessage() {
            UnknownMessageAnalyticsTracker.tagUnknownMessage(with: moc.analytics)
        }
        
        // Verify sender is part of conversation
        conversation.verifySender(of: updateEvent, moc: moc)
        
        // Insert the message
        if message.hasLastRead() && conversation.isSelfConversation {
            ZMConversation.updateConversationWithZMLastRead(fromSelfConversation: message.lastRead, in: moc)
        } else if message.hasCleared() && conversation.isSelfConversation {
            ZMConversation.updateConversationWithZMCleared(fromSelfConversation: message.cleared, in: moc)
        } else if message.hasHidden() && conversation.isSelfConversation {
            ZMMessage.removeMessage(withRemotelyHiddenMessage: message.hidden, in: moc)
        } else if message.hasDeleted() {
            ZMMessage.removeMessage(withRemotelyDeletedMessage: message.deleted, in: conversation, senderID: senderID, in: moc)
        } else if message.hasReaction() {
            // if we don't understand the reaction received, discard it
            guard Reaction.validate(unicode: message.reaction.emoji) else {
                return nil
            }
            ZMMessage.add(message.reaction, senderID: senderID, conversation: conversation, in: moc)
        } else if message.hasConfirmation() {
            ZMMessageConfirmation.createMessageConfirmations(message.confirmation, conversation: conversation, updateEvent: updateEvent)
        } else if message.hasButtonActionConfirmation() {
            ZMClientMessage.updateButtonStates(withConfirmation: message.buttonActionConfirmation, forConversation: conversation, inContext: moc)
        } else if message.hasEdited() {
            return ZMClientMessage.editMessage(withEdit: message.edited, forConversation: conversation, updateEvent: updateEvent, inContext: moc, prefetchResult: prefetchResult)
        } else if conversation.shouldAdd(event: updateEvent) && !(message.hasClientAction() || message.hasCalling() || message.hasAvailability()) {
            guard let nonce = UUID(uuidString: message.messageId) else { return nil }
            let messageClass: AnyClass = ZMGenericMessage.entityClass(for: message)
            var clientMessage = messageClass.fetch(withNonce: nonce, for: conversation, in: moc, prefetchResult: prefetchResult) as? ZMOTRMessage
            
            guard !isZombieObject(clientMessage) else {
                return nil
            }
            
            var isNewMessage = false
            if clientMessage == nil {
                isNewMessage = true
                
                if messageClass is ZMClientMessage.Type {
                    clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: moc)
                } else if messageClass is ZMAssetClientMessage.Type {
                    clientMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: moc)
                } else {
                    return nil
                }
                
                clientMessage?.senderClientID = updateEvent.senderClientID()
                clientMessage?.serverTimestamp = updateEvent.timeStamp()
                
                if isGroup(conversation: conversation, andIsSenderID: senderID, differentFromSelfUserID: selfUser.remoteIdentifier) {
                    clientMessage?.expectsReadConfirmation = conversation.hasReadReceiptsEnabled || message.hasComposite()
                }
            } else if clientMessage?.senderClientID == nil || clientMessage?.senderClientID != updateEvent.senderClientID() {
                return nil
            }
            
            // In case of AssetMessages: If the payload does not match the sha265 digest, calling `updateWithGenericMessage:updateEvent` will delete the object.
            clientMessage?.update(with: updateEvent, initialUpdate: isNewMessage)

            // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true.
            // In addition the object will still have a managedObjectContext until the context is finally saved. In this
            // case, we need to check the nonce (which would have previously been set) to avoid setting an invalid
            // relationship between the deleted object and the conversation and / or sender
            guard !isZombieObject(clientMessage) && clientMessage?.nonce != nil else {
                return nil
            }
            
            clientMessage?.update(with: updateEvent, for: conversation)
            clientMessage?.unarchiveIfNeeded(conversation)
            clientMessage?.updateCategoryCache()
            
            return clientMessage
        }
        return nil
    }
    
    private static func isZombieObject(_ message: ZMOTRMessage?) -> Bool {
        guard let message = message else { return false }
        return message.isZombieObject
    }
    
    private static func isSelf(conversation: ZMConversation, andIsSenderID senderID: UUID, differentFromSelfUserID selfUserID: UUID) -> Bool {
        return conversation.isSelfConversation && senderID != selfUserID
    }
    
    private static func isGroup(conversation: ZMConversation, andIsSenderID senderID: UUID, differentFromSelfUserID selfUserID: UUID) -> Bool {
        return conversation.conversationType == .group && senderID != selfUserID
    }
    
    private static func appendInvalidSystemMessage(forUpdateEvent event: ZMUpdateEvent, toConversation conversation: ZMConversation, inContext moc: NSManagedObjectContext) {
        guard let remoteId = event.senderUUID(),
            let sender = ZMUser(remoteID: remoteId, createIfNeeded: false, in: moc) else {
                return
        }
        conversation.appendInvalidSystemMessage(at: event.timeStamp() ?? Date(), sender: sender)
    }
}
