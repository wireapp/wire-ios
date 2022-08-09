//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

    // MARK: - Keys

    @objc
    static let messageProtocolKey = "messageProtocol"

    @objc
    static let mlsGroupID = "mlsGroupID"

    // MARK: - Properties

    @NSManaged private var primitiveMessageProtocol: NSNumber

    /// The message protocol used to exchange messages in this conversation.

    public var messageProtocol: MessageProtocol {
        get {
            willAccessValue(forKey: Self.messageProtocolKey)
            let value = primitiveMessageProtocol.int16Value
            didAccessValue(forKey: Self.messageProtocolKey)

            guard let result = MessageProtocol(rawValue: value) else {
                fatalError("failed to init MessageProtocol from rawValue: \(value)")
            }

            return result
        }

        set {
            willChangeValue(forKey: Self.messageProtocolKey)
            primitiveMessageProtocol = NSNumber(value: newValue.rawValue)
            didChangeValue(forKey: Self.messageProtocolKey)
        }
    }

    @NSManaged private var primitiveMlsGroupID: Data?

    /// The mls group identifer.
    ///
    /// If this conversation is an mls group (which it should be if the
    /// `messageProtocol` is `mls`), then this identifier should exist.

    public var mlsGroupID: MLSGroupID? {
        get {
            willAccessValue(forKey: Self.mlsGroupID)
            let value = primitiveMlsGroupID
            didAccessValue(forKey: Self.mlsGroupID)
            return value.map(MLSGroupID.init(_:))
        }

        set {
            willChangeValue(forKey: Self.mlsGroupID)
            primitiveMlsGroupID = newValue?.data
            didChangeValue(forKey: Self.mlsGroupID)
        }
    }

    /// Whether the conversation is pending processing of an
    /// mls welcome message.
    ///
    /// Until the welcome message is processed, this conversation
    /// is not ready for communication.

    @NSManaged public var isPendingWelcomeMessage: Bool

}

// MARK: - Fetch by group id

public extension ZMConversation {

    static func fetch(
        with groupID: MLSGroupID,
        domain: String,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        let request = Self.fetchRequest()
        request.fetchLimit = 2

        if APIVersion.isFederationEnabled {
            request.predicate = NSPredicate(
                format: "%K == %@ AND %K == %@",
                argumentArray: [Self.mlsGroupID, groupID.data, Self.domainKey()!, domain]
            )
        } else {
            request.predicate = NSPredicate(
                format: "%K == %@",
                argumentArray: [Self.mlsGroupID, groupID.data]
            )
        }

        let result = context.executeFetchRequestOrAssert(request)
        require(result.count <= 1, "More than one conversation found for a single group id")
        return result.first as? ZMConversation
    }

}
