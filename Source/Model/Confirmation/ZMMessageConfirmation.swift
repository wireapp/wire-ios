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
    case Delivered, Read
    
    static func convert(zmConfirmationType: ZMConfirmationType) -> MessageConfirmationType {
        switch zmConfirmationType {
        case .DELIVERED:
            return .Delivered
        case .READ:
            return .Read
        }
    }
}

@objc(ZMMessageConfirmation)
public class ZMMessageConfirmation: NSManagedObject {

    @NSManaged public var type: MessageConfirmationType
    @NSManaged public var message: ZMMessage
    @NSManaged public var user: ZMUser

    static var entityName: String {
        return "MessageConfirmation"
    }
    
    /// Creates a ZMMessageConfirmation object that holds a reference to a message that was confirmed and the user who confirmed it.
    /// It can have 2 types: Delivered and Read depending on the genericMessage confirmation type
    static public func createOrUpdateMessageConfirmation(genericMessage: ZMGenericMessage, conversation: ZMConversation, sender: ZMUser) -> ZMMessageConfirmation? {
        
        guard genericMessage.hasConfirmation(),
            let moc = conversation.managedObjectContext,
            let messageUUID = NSUUID(UUIDString: genericMessage.confirmation.messageId),
            let message = ZMMessage.fetchMessageWithNonce(messageUUID, forConversation: conversation, inManagedObjectContext: moc),
            let originalSender = message.sender where originalSender.isSelfUser
        else { return nil }
        
        var confirmation = message.confirmations.filter{$0.user == sender}.first
        if confirmation == nil {
            confirmation = NSEntityDescription.insertNewObjectForEntityForName(ZMMessageConfirmation.entityName, inManagedObjectContext: moc) as? ZMMessageConfirmation
        }
        confirmation?.user = sender
        confirmation?.message = message
        confirmation?.type = MessageConfirmationType.convert(genericMessage.confirmation.type)
        
        return confirmation
    }
}
