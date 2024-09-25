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

import Foundation

public enum Recipients {
    case conversationParticipants
    case users(Set<ZMUser>)
    case clients([ZMUser: Set<UserClient>])
}

@objcMembers public class GenericMessageEntity: NSObject, ProteusMessage {

    public var context: NSManagedObjectContext
    public var message: GenericMessage
    public var conversation: ZMConversation?
    public var completionHandler: ((_ response: ZMTransportResponse) -> Void)?
    public var isExpired: Bool = false
    public var expirationDate: Date?
    public var expirationReasonCode: NSNumber?

    public let targetRecipients: Recipients

    public init(message: GenericMessage,
                context: NSManagedObjectContext,
                conversation: ZMConversation? = nil,
                targetRecipients: Recipients = .conversationParticipants,
                completionHandler: ((_ response: ZMTransportResponse) -> Void)?) {
        self.context = context
        self.conversation = conversation
        self.message = message
        self.targetRecipients = targetRecipients
        self.completionHandler = completionHandler
    }

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        guard let conversation else { return nil }

        return self.dependentObjectNeedingUpdateBeforeProcessingOTREntity(in: conversation)
    }

    public var shouldIgnoreTheSecurityLevelCheck: Bool = false

    public func missesRecipients(_ recipients: Set<UserClient>) {
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

    public func prepareMessageForSending() async throws {
        // no-op
    }
    
    public func setUnderlyingMessage(_ message: WireProtos.GenericMessage) throws {
        self.message = message
    }

    public var underlyingMessage: WireProtos.GenericMessage? {
        message
    }

    public func expire(withReason reason: ExpirationReason) {
        isExpired = true
        expirationReasonCode = NSNumber(value: reason.rawValue)
    }

    public override var hash: Int {
        return self.message.hashValue
    }
}

public func == (lhs: GenericMessageEntity, rhs: GenericMessageEntity) -> Bool {
    return lhs === rhs
}
