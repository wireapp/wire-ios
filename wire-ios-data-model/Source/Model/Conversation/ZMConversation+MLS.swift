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
import WireUtilities

extension ZMConversation {
    // MARK: Keys

    @objc public static let messageProtocolKey = "messageProtocol"

    @objc static let mlsGroupIdKey = "mlsGroupID"

    @objc static let mlsStatusKey = "mlsStatus"

    @objc static let mlsVerificationStatusKey = "mlsVerificationStatus"

    @objc static let commitPendingProposalDateKey = "commitPendingProposalDate"

    @objc static let ciphersuiteKey = "ciphersuite"

    @objc static let epochKey = #keyPath(epoch)

    @objc static let epochTimestampKey = #keyPath(epochTimestamp)

    // MARK: Properties

    @NSManaged private var primitiveCiphersuite: NSNumber?

    @NSManaged public var epoch: UInt64

    @NSManaged public var epochTimestamp: Date?

    @NSManaged private var primitiveMessageProtocol: NSNumber

    public var ciphersuite: MLSCipherSuite? {
        get {
            willAccessValue(forKey: Self.ciphersuiteKey)
            let rawValue = primitiveCiphersuite
            didAccessValue(forKey: Self.ciphersuiteKey)

            guard let rawValue else {
                return nil
            }

            return MLSCipherSuite(rawValue: Int(rawValue.int16Value))
        }

        set {
            willChangeValue(forKey: Self.ciphersuiteKey)
            primitiveCiphersuite = newValue.map { NSNumber(value: $0.rawValue) }
            didChangeValue(forKey: Self.ciphersuiteKey)
        }
    }

    /// The message protocol used to exchange messages in this conversation.

    public var messageProtocol: MessageProtocol {
        get {
            willAccessValue(forKey: Self.messageProtocolKey)
            let value = primitiveMessageProtocol.int16Value
            didAccessValue(forKey: Self.messageProtocolKey)

            guard let result = MessageProtocol(int16Value: value) else {
                fatalError("failed to init MessageProtocol from rawValue: \(value)")
            }

            return result
        }

        set {
            willChangeValue(forKey: Self.messageProtocolKey)
            primitiveMessageProtocol = NSNumber(value: newValue.int16Value)
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
            willAccessValue(forKey: Self.mlsGroupIdKey)
            let value = primitiveMlsGroupID
            didAccessValue(forKey: Self.mlsGroupIdKey)
            return value.map(MLSGroupID.init(_:))
        }

        set {
            willChangeValue(forKey: Self.mlsGroupIdKey)
            primitiveMlsGroupID = newValue?.data
            didChangeValue(forKey: Self.mlsGroupIdKey)
        }
    }

    @NSManaged private var primitiveMlsStatus: NSNumber?

    /// The mls group status
    ///
    /// If this conversation is an mls group (which it should be if the
    /// `messageProtocol` is `mls`), then this status should exist.
    public var mlsStatus: MLSGroupStatus? {
        get {
            willAccessValue(forKey: Self.mlsStatusKey)
            let value = primitiveMlsStatus?.int16Value
            didAccessValue(forKey: Self.mlsStatusKey)

            guard let value else {
                return nil
            }

            guard let status = MLSGroupStatus(rawValue: value) else {
                fatalError("failed to init MLSGroupStatus from rawValue: \(value)")
            }

            return status
        }

        set {
            willChangeValue(forKey: Self.mlsStatusKey)
            primitiveMlsStatus = newValue.map { NSNumber(value: $0.rawValue) }
            didChangeValue(forKey: Self.mlsStatusKey)
        }
    }

    /// Point in time when the pending proposals in the conversation
    /// should be committed. If nil there's no pending proposals
    /// to commit.
    @NSManaged public var commitPendingProposalDate: Date?

    /// The mls verification status.
    ///
    /// If this conversation is an mls group (which it should be if the
    /// `messageProtocol` is `mls`), then this identifier should exist.

    public var mlsVerificationStatus: MLSVerificationStatus? {
        get {
            willAccessValue(forKey: Self.mlsVerificationStatusKey)
            let value = primitiveValue(forKey: Self.mlsVerificationStatusKey) as? MLSVerificationStatus.RawValue
            didAccessValue(forKey: Self.mlsVerificationStatusKey)

            guard let value else { return nil }
            guard let status = MLSVerificationStatus(rawValue: value) else {
                return nil
            }
            return status
        }
        set {
            willChangeValue(forKey: Self.mlsVerificationStatusKey)
            setPrimitiveValue(newValue?.rawValue, forKey: Self.mlsVerificationStatusKey)
            didChangeValue(forKey: Self.mlsVerificationStatusKey)
        }
    }
}

// MARK: - Fetch by group id

extension ZMConversation {
    public static func fetch(
        with groupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        let request = Self.fetchRequest()
        request.fetchLimit = 2

        request.predicate = NSPredicate(
            format: "%K == %@",
            argumentArray: [Self.mlsGroupIdKey, groupID.data]
        )

        let result = try! context.fetch(request)
        require(result.count <= 1, "More than one conversation found for a single group id")
        return result.first as? ZMConversation
    }

    public static func fetchConversationsWithPendingProposals(
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        let request = Self.fetchRequest()

        request.predicate = NSPredicate(
            format: "%K != nil",
            argumentArray: [Self.commitPendingProposalDateKey]
        )

        return try! context.fetch(request) as? [ZMConversation] ?? []
    }

    public static func fetchConversationsWithMLSGroupStatus(
        mlsGroupStatus: MLSGroupStatus,
        in context: NSManagedObjectContext
    ) throws -> [ZMConversation] {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        let matchingGroupStatus = NSPredicate(
            format: "%K == \(mlsGroupStatus.rawValue)",
            argumentArray: [Self.mlsStatusKey]
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            matchingGroupStatus, .isMLSConversation,
        ])

        return try context.fetch(request)
    }

    public static func fetchSelfMLSConversation(
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        let request = Self.fetchRequest()
        request.fetchLimit = 2
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .hasConversationType(.`self`), .isMLSConversation,
        ])

        let result = try! context.fetch(request)
        require(result.count <= 1, "More than one conversation found for a single group id")
        return result.first as? ZMConversation
    }

    public static func fetchMLSConversations(in context: NSManagedObjectContext) -> [ZMConversation] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName())
        request.predicate = .isMLSConversation
        return context.fetchOrAssert(request: request)
    }

    public func joinNewMLSGroup(id mlsGroupID: MLSGroupID, completion: ((Error?) -> Void)?) {
        guard let syncContext = managedObjectContext?.zm_sync else {
            completion?(JoinNewMLSGroupError.couldNotFindSyncContext)
            return
        }

        syncContext.perform {
            guard let mlsService = syncContext.mlsService else { return }

            Task {
                do {
                    try await mlsService.joinNewGroup(with: mlsGroupID)
                } catch {
                    WireLogger.mls.error("failed to join new MLS Group \(mlsGroupID.safeForLoggingDescription)")
                    completion?(error)
                    return
                }
                completion?(nil)
            }
        }
    }

    public enum JoinNewMLSGroupError: Error {
        case couldNotFindSyncContext
    }
}

// MARK: - Migration releated fetch requests

extension ZMConversation {
    public static func fetchAllTeamGroupConversations(
        messageProtocol: MessageProtocol,
        in context: NSManagedObjectContext
    ) throws -> [ZMConversation] {
        let selfUser = ZMUser.selfUser(in: context)
        guard let selfUserTeamIdentifier = selfUser.teamIdentifier else {
            assertionFailure("this method is supposed to be called for users which are part of a team")
            return []
        }

        let request = NSFetchRequest<Self>(entityName: Self.entityName())
        request.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .hasConversationType(.group),
                .hasMessageProtocol(messageProtocol),
                .teamRemoteIdentifier(matches: selfUserTeamIdentifier),
            ]
        )

        return try context.fetch(request)
    }
}

// MARK: - NSPredicate Extensions

extension NSPredicate {
    fileprivate static var isMLSConversation: NSPredicate {
        NSPredicate(
            format: "%K == %i && %K != nil",
            argumentArray: [
                ZMConversation.messageProtocolKey,
                MessageProtocol.mls.int16Value,
                ZMConversation.mlsGroupIdKey,
            ]
        )
    }

    fileprivate static func hasConversationType(_ conversationType: ZMConversationType) -> NSPredicate {
        .init(
            format: "%K == %i",
            argumentArray: [
                ZMConversationConversationTypeKey,
                conversationType.rawValue,
            ]
        )
    }

    fileprivate static func hasMessageProtocol(_ messageProtocol: MessageProtocol) -> NSPredicate {
        .init(
            format: "%K == %i",
            argumentArray: [
                ZMConversation.messageProtocolKey,
                messageProtocol.int16Value,
            ]
        )
    }

    fileprivate static func teamRemoteIdentifier(matches teamRemoteIdentifier: UUID) -> NSPredicate {
        .init(
            format: "%K == %@",
            argumentArray: [
                TeamRemoteIdentifierDataKey,
                (teamRemoteIdentifier as NSUUID).data() as Data,
            ]
        )
    }
}
