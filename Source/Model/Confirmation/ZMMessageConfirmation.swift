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
import CoreData


@objc public enum MessageConfirmationType : Int16 {
    case delivered, read
    
    static func convert(_ zmConfirmationType: ZMConfirmationType) -> MessageConfirmationType {
        switch zmConfirmationType {
        case .DELIVERED:
            return .delivered
        case .READ:
            return .read
        }
    }
}

@objc(ZMMessageConfirmation) @objcMembers
open class ZMMessageConfirmation: ZMManagedObject {

    @NSManaged open var type: MessageConfirmationType
    @NSManaged open var message: ZMMessage
    @NSManaged open var user: ZMUser

    override open class func entityName() -> String {
        return "MessageConfirmation"
    }
    
    open override var modifiedKeys: Set<AnyHashable>? {
        get {
            return Set()
        } set {
            // do nothing
        }
    }
    
    
    /// Creates a ZMMessageConfirmation object that holds a reference to a message that was confirmed and the user who confirmed it.
    /// It can have 2 types: Delivered and Read depending on the genericMessage confirmation type
    public static func createOrUpdateMessageConfirmation(_ genericMessage: ZMGenericMessage, conversation: ZMConversation, sender: ZMUser) -> ZMMessageConfirmation? {
        
        guard genericMessage.hasConfirmation(),
            let moc = conversation.managedObjectContext,
            let messageUUID = UUID(uuidString: genericMessage.confirmation.firstMessageId),
            let message = ZMMessage.fetch(withNonce: messageUUID, for: conversation, in: moc),
            let originalSender = message.sender, originalSender.isSelfUser
        else { return nil }
        
        var confirmation = message.confirmations.filter{$0.user == sender}.first
        if confirmation == nil {
            confirmation = NSEntityDescription.insertNewObject(forEntityName: ZMMessageConfirmation.entityName(), into: moc) as? ZMMessageConfirmation
        }
        confirmation?.user = sender
        confirmation?.message = message
        confirmation?.type = MessageConfirmationType.convert(genericMessage.confirmation.type)
        
        return confirmation
    }
}
