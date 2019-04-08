//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
    
    @NSManaged @objc dynamic public var hasReadReceiptsEnabled: Bool
    
    /// Confirm unread received messages as read.
    ///
    /// - parameter until: unread messages received up until this timestamp will be confirmed as read.
    @discardableResult
    func confirmUnreadMessagesAsRead(until timestamp: Date) -> [ZMClientMessage] {
        
        let unreadMessagesNeedingConfirmation = unreadMessages(until: timestamp).filter({ $0.needsReadConfirmation })
        var confirmationMessages: [ZMClientMessage] = []
        
        for messages in unreadMessagesNeedingConfirmation.partition(by: \.sender).values {
            guard !messages.isEmpty else { continue }
            
            let confirmation = ZMConfirmation.confirm(messages: messages.compactMap(\.nonce), type: .READ)
            
            if let confirmationMessage = append(message: confirmation, hidden: true) {
                confirmationMessages.append(confirmationMessage)
            }
        }
        
        return confirmationMessages
    }
    
    public static func confirmDeliveredMessages(_ messages: Set<UUID>, in conversations: Set<UUID>, with managedObjectContext: NSManagedObjectContext) -> [ZMMessage] {
        guard let conversationObjects = ZMConversation.fetchObjects(withRemoteIdentifiers: conversations, in: managedObjectContext) as? Set<ZMConversation> else { return [] }
        var confirmationMessages: [ZMMessage] = []
        
        for conversation in conversationObjects {
            guard let confirmation = conversation.appendConfirmationMessage(for: messages, in: managedObjectContext)
                else { continue }
            confirmationMessages.append(confirmation)
        }
        
        return confirmationMessages
    }
    
    private func appendConfirmationMessage(for messages: Set<UUID>, in managedObjectContext: NSManagedObjectContext) -> ZMMessage? {
        guard let messageObjects = ZMOTRMessage.fetchObjects(withRemoteIdentifiers: messages, in: managedObjectContext) as? Set<ZMOTRMessage>
            else { return nil }
        
        let deliveredMessages = messageObjects.filter { $0.conversation == self && $0.needsDeliveryConfirmation }.compactMap(\.nonce)
        
        guard deliveredMessages.count > 0 else { return nil }
        return append(message: ZMConfirmation.confirm(messages: deliveredMessages, type: .DELIVERED), hidden: true)
    }
    
    @discardableResult @objc
    public func appendMessageReceiptModeChangedMessage(fromUser user: ZMUser, timestamp: Date, enabled: Bool) -> ZMSystemMessage {
        let message = appendSystemMessage(
            type: enabled ? .readReceiptsEnabled : .readReceiptsDisabled,
            sender: user,
            users: [],
            clients: nil,
            timestamp: timestamp
        )
        
        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }
        
        return message
    }
    
    @discardableResult @objc
    public func appendMessageReceiptModeIsOnMessage(timestamp: Date) -> ZMSystemMessage {
        let message = appendSystemMessage(
            type: .readReceiptsOn,
            sender: creator,
            users: [],
            clients: nil,
            timestamp: timestamp
        )
        
        return message
    }
    
}
