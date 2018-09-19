//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireCryptobox

extension ZMConversation {
    static func appendHideMessageToSelfConversation(_ message: ZMMessage) {
        guard let messageId = message.nonce,
              let conversation = message.conversation,
              let conversationId = conversation.remoteIdentifier
        else { return }
        
        let genericMessage = ZMGenericMessage.message(content: ZMMessageHide.hide(conversationId: conversationId, messageId: messageId))
        ZMConversation.appendSelfConversation(with: genericMessage, managedObjectContext: message.managedObjectContext!)
    }
}

extension ZMMessage {
    
    // NOTE: This is a free function meant to be called from Obj-C because you can't call protocol extension from it
    @objc public static func hideMessage(_ message: ZMConversationMessage) {
        // when deleting ephemeral, we must delete for everyone (only self & sender will receive delete message)
        // b/c deleting locally will void the destruction timer completion.
        guard !message.isEphemeral else { deleteForEveryone(message); return }
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.hideForSelfUser()
    }
    
    @objc public func hideForSelfUser() {
        guard !isZombieObject else { return }
        ZMConversation.appendHideMessageToSelfConversation(self)

        // To avoid reinserting when receiving an edit we delete the message locally
        removeClearingSender(true)
        managedObjectContext?.delete(self)
    }
    
    @discardableResult @objc public static func deleteForEveryone(_ message: ZMConversationMessage) -> ZMClientMessage? {
        guard let castedMessage = message as? ZMMessage else { return nil }
        return castedMessage.deleteForEveryone()
    }
    
    @discardableResult @objc func deleteForEveryone() -> ZMClientMessage? {
        guard !isZombieObject, let sender = sender , (sender.isSelfUser || isEphemeral) else { return nil }
        guard let conversation = conversation, let messageNonce = nonce else { return nil}
        
        let message =  conversation.append(message: ZMMessageDelete.delete(messageId: messageNonce), hidden: true)
        
        removeClearingSender(false)
        updateCategoryCache()
        return message
    }
    
    @objc public static func edit(_ message: ZMConversationMessage, newText: String, mentions: [Mention] = [], fetchLinkPreview: Bool = true) -> ZMMessage? {
        guard let castedMessage = message as? ZMMessage else { return nil }
        return castedMessage.edit(newText, mentions: mentions, fetchLinkPreview: fetchLinkPreview)
    }
        
    func edit(_ newText: String, mentions: [Mention] = [], fetchLinkPreview: Bool) -> ZMMessage? {
        guard isEditableMessage else { return nil }
        guard !isZombieObject, let sender = sender , sender.isSelfUser else { return nil }
        guard let conversation = conversation, let messageNonce = nonce else { return nil }
        guard let newMessage = conversation.append(message: ZMMessageEdit.edit(with: ZMText.text(with: newText, mentions: mentions), replacingMessageId: messageNonce), expires: true) else { return nil }
        
        newMessage.updatedTimestamp = newMessage.serverTimestamp
        newMessage.serverTimestamp = serverTimestamp
        let oldIndex = conversation.messages.index(of: self)
        let newIndex = conversation.messages.index(of: newMessage)
        conversation.mutableMessages.moveObjects(at: IndexSet(integer:newIndex), to: oldIndex)

        hiddenInConversation = conversation
        visibleInConversation = nil
        normalizedText = nil
        newMessage.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        return newMessage
    }
    
    @objc var isEditableMessage : Bool {
        return false
    }
}

extension ZMClientMessage {
    override var isEditableMessage : Bool {
        if let genericMsg = genericMessage {
            return (self.sender?.isSelfUser ?? false) &&
                   (genericMsg.hasEdited() ||
                       (genericMsg.hasText() && !isEphemeral && (deliveryState == .sent || deliveryState == .delivered)))
        }
        return false
    }
}



