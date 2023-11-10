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
import WireUtilities

extension ZMConversation {

    // MARK: Keys

    @objc
    static let messageProtocolKey = "messageProtocol"

    @objc
    static let mlsGroupIdKey = "mlsGroupID"

    @objc
    static let mlsStatusKey = "mlsStatus"

    @objc
    static let commitPendingProposalDateKey = "commitPendingProposalDate"

    @objc
    static let epochKey = #keyPath(epoch)

    // MARK: Properties

    @NSManaged public var epoch: UInt64

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

            guard let value = value else {
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

}

// MARK: - Fetch by group id

public extension ZMConversation {

    static func fetch(
        with groupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        let request = Self.fetchRequest()
        request.fetchLimit = 2

        request.predicate = NSPredicate(
            format: "%K == %@",
            argumentArray: [Self.mlsGroupIdKey, groupID.data]
        )

        let result = context.executeFetchRequestOrAssert(request)
        require(result.count <= 1, "More than one conversation found for a single group id")
        return result.first as? ZMConversation
    }

    static func fetchConversationsWithPendingProposals(
        in context: NSManagedObjectContext
    ) -> [ZMConversation] {
        let request = Self.fetchRequest()

        request.predicate = NSPredicate(
            format: "%K != nil",
            argumentArray: [Self.commitPendingProposalDateKey]
        )

        return context.executeFetchRequestOrAssert(request) as? [ZMConversation] ?? []
    }

    static func fetchSelfMLSConversation(
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        let request = Self.fetchRequest()
        request.fetchLimit = 2
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .hasConversationType(.`self`), .isMLSConversation
        ])

        let result = context.executeFetchRequestOrAssert(request)
        require(result.count <= 1, "More than one conversation found for a single group id")
        return result.first as? ZMConversation
    }

    static func fetchMLSConversations(in context: NSManagedObjectContext) -> [ZMConversation] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName())
        request.predicate = .isMLSConversation
        return context.fetchOrAssert(request: request)
    }

    func joinNewMLSGroup(id mlsGroupID: MLSGroupID, completion: ((Error?) -> Void)?) {
        guard let syncContext = self.managedObjectContext?.zm_sync else {
            completion?(ZMConversationError.couldNotFindSyncContext)
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
}

// MARK: - Migration releated fetch requests

public extension ZMConversation {

    static func fetchAllTeamGroupProteusConversations(in context: NSManagedObjectContext) throws -> [ZMConversation] {
        let selfUser = ZMUser.selfUser(in: context)
        guard let selfUserTeamIdentifier = selfUser.teamIdentifier else {
            assertionFailure("this method is supposed to be called for users which are part of a team")
            return []
        }

        let request = NSFetchRequest<Self>(entityName: Self.entityName())
        request.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .hasConversationType(.group),
                .hasMessageProtocol(.proteus),
                .teamRemoteIdentifier(matches: selfUserTeamIdentifier)
            ]
        )

        return try context.fetch(request)
    }
}

// MARK: -

extension ZMConversation {

    enum ZMConversationError: Error {
        case couldNotFindSyncContext
    }
}

// MARK: -

private extension NSPredicate {

    static var isMLSConversation: NSPredicate {
        NSPredicate(
            format: "%K == %i && %K != nil",
            argumentArray: [
                ZMConversation.messageProtocolKey,
                MessageProtocol.mls.rawValue,
                ZMConversation.mlsGroupIdKey
            ]
        )
    }

    static func hasConversationType(_ conversationType: ZMConversationType) -> NSPredicate {
        .init(
            format: "%K == %i",
            argumentArray: [
                ZMConversationConversationTypeKey,
                conversationType.rawValue
            ]
        )
    }

    static func hasMessageProtocol(_ messageProtocol: MessageProtocol) -> NSPredicate {
        .init(
            format: "%K == %i",
            argumentArray: [
                ZMConversation.messageProtocolKey,
                messageProtocol.rawValue
            ]
        )
    }

    static func teamRemoteIdentifier(matches teamRemoteIdentifier: UUID) -> NSPredicate {
        .init(
            format: "%K == %@",
            argumentArray: [
                TeamRemoteIdentifierDataKey,
                (teamRemoteIdentifier as NSUUID).data() as Data
            ]
        )
    }
}
