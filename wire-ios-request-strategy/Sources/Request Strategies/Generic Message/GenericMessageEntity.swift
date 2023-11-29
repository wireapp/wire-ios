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

@objcMembers public class GenericMessageEntity: NSObject, ProteusMessage {

    public enum Recipients {
        case conversationParticipants
        case users(Set<ZMUser>)
        case clients([ZMUser: Set<UserClient>])
    }

    public var message: GenericMessage
    public var conversation: ZMConversation?
    public var completionHandler: ((_ response: ZMTransportResponse) -> Void)?
    public var isExpired: Bool = false
    public var expirationDate: Date?
    public var expirationReasonCode: NSNumber?

    public let targetRecipients: Recipients

    public init(conversation: ZMConversation, message: GenericMessage, targetRecipients: Recipients = .conversationParticipants, completionHandler: ((_ response: ZMTransportResponse) -> Void)?) {
        self.conversation = conversation
        self.message = message
        self.targetRecipients = targetRecipients
        self.completionHandler = completionHandler
    }

    public var context: NSManagedObjectContext {
        return conversation!.managedObjectContext!
    }

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        guard let conversation  = conversation else { return nil }

        return self.dependentObjectNeedingUpdateBeforeProcessingOTREntity(in: conversation)
    }

    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // no-op
    }

    public func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        // no-op
    }

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        // no-op
    }

    public func delivered(with response: ZMTransportResponse) {
        // no-op
    }

    public func expire() {
        isExpired = true
    }

    public override var hash: Int {
        return self.message.hashValue
    }
}

public func == (lhs: GenericMessageEntity, rhs: GenericMessageEntity) -> Bool {
    return lhs === rhs
}

extension GenericMessageEntity: EncryptedPayloadGenerator {

    public func encryptForTransport() -> EncryptedPayloadGenerator.Payload? {
        guard
            let conversation = conversation,
            let managedObjectContext = conversation.managedObjectContext
        else {
            return nil
        }

        switch targetRecipients {
        case .conversationParticipants:
            return message.encryptForTransport(for: conversation)
        case .users(let users):
            return message.encryptForTransport(forBroadcastRecipients: users, in: managedObjectContext)
        case .clients(let clientsByUser):
            return message.encryptForTransport(for: clientsByUser, in: managedObjectContext)
        }
    }

    public func encryptForTransportQualified() -> EncryptedPayloadGenerator.Payload? {
        guard
            let conversation = conversation,
            let managedObjectContext = conversation.managedObjectContext
        else {
            return nil
        }

        switch targetRecipients {
        case .conversationParticipants:
            return message.encryptForTransport(for: conversation, useQualifiedIdentifiers: true)
        case .users(let users):
            return message.encryptForTransport(forBroadcastRecipients: users, useQualifiedIdentifiers: true, in: managedObjectContext)
        case .clients(let clientsByUser):
            return message.encryptForTransport(for: clientsByUser, useQualifiedIdentifiers: true, in: managedObjectContext)
        }
    }

    public var debugInfo: String {
        if case .confirmation = message.content {
            return "Confirmation Message"
        } else if case .calling? = message.content {
            return "Calling Message"
        } else if case .clientAction? = message.content {
            switch message.clientAction {
            case .resetSession: return "Reset Session Message"
            @unknown default:
                return "unknown Message"
            }
        }

        return "\(self)"
    }

}
