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

// MARK: - GenericMessageEntity

@objcMembers
public class GenericMessageEntity: NSObject, ProteusMessage {
    public enum Recipients {
        case conversationParticipants
        case users(Set<ZMUser>)
        case clients([ZMUser: Set<UserClient>])
    }

    public var context: NSManagedObjectContext
    public var message: GenericMessage
    public var conversation: ZMConversation?
    public var completionHandler: ((_ response: ZMTransportResponse) -> Void)?
    public var isExpired = false
    public var expirationDate: Date?
    public var expirationReasonCode: NSNumber?

    public let targetRecipients: Recipients

    public init(
        message: GenericMessage,
        context: NSManagedObjectContext,
        conversation: ZMConversation? = nil,
        targetRecipients: Recipients = .conversationParticipants,
        completionHandler: ((_ response: ZMTransportResponse) -> Void)?
    ) {
        self.context = context
        self.conversation = conversation
        self.message = message
        self.targetRecipients = targetRecipients
        self.completionHandler = completionHandler
    }

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        guard let conversation else { return nil }

        return dependentObjectNeedingUpdateBeforeProcessingOTREntity(in: conversation)
    }

    public var shouldIgnoreTheSecurityLevelCheck = false

    public func missesRecipients(_: Set<UserClient>!) {
        // no-op
    }

    public func addFailedToSendRecipients(_: [ZMUser]) {
        // no-op
    }

    public func detectedRedundantUsers(_: [ZMUser]) {
        // no-op
    }

    public func delivered(with response: ZMTransportResponse) {
        // no-op
    }

    public func expire() {
        isExpired = true
    }

    override public var hash: Int {
        message.hashValue
    }
}

public func == (lhs: GenericMessageEntity, rhs: GenericMessageEntity) -> Bool {
    lhs === rhs
}

// MARK: EncryptedPayloadGenerator

extension GenericMessageEntity: EncryptedPayloadGenerator {
    public func encryptForTransport() async -> EncryptedPayloadGenerator.Payload? {
        switch targetRecipients {
        case .conversationParticipants:
            guard let conversation else { return nil }
            return await message.encryptForTransport(for: conversation, in: context)

        case let .users(users):
            return await message.encryptForTransport(forBroadcastRecipients: users, in: context)

        case let .clients(clientsByUser):
            return await message.encryptForTransport(for: clientsByUser, in: context)
        }
    }

    public func encryptForTransportQualified() async -> EncryptedPayloadGenerator.Payload? {
        switch targetRecipients {
        case .conversationParticipants:
            guard let conversation else { return nil }
            return await message.encryptForTransport(for: conversation, in: context, useQualifiedIdentifiers: true)

        case let .users(users):
            return await message.encryptForTransport(
                forBroadcastRecipients: users,
                useQualifiedIdentifiers: true,
                in: context
            )

        case let .clients(clientsByUser):
            return await message.encryptForTransport(for: clientsByUser, useQualifiedIdentifiers: true, in: context)
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
            }
        }

        return "\(self)"
    }
}
