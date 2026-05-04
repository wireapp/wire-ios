//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public extension ZMConversation {

    typealias ConversationID = UUID

    /// Whether the conversation was deleted on the backend.

    @NSManaged var isDeletedRemotely: Bool

    /// Whether the conversation is marked as read only

    @NSManaged var isForcedReadOnly: Bool

    /// The other user of a one on one conversation.

    @NSManaged var oneOnOneUser: ZMUser?

    /// True until the metadata has been fetched for the first time

    @NSManaged var isPendingInitialFetch: Bool

    /// True if this mls conversation was migrated from another proteus conversation.
    ///
    /// This property is only relevant for mls 1-1 conversation where 1-1 proteus conversation's messages where moved
    /// to.
    /// - Note: This could be removed once the MLS migration is completed.
    @NSManaged var migratedToMLS: Bool

    // MARK: - CoreData unique constraint

    internal static let domainKey: String = "domain"
    @NSManaged private var primitiveDomain: String?
    var domain: String? {
        get {
            willAccessValue(forKey: Self.domainKey)
            let value = primitiveDomain
            didAccessValue(forKey: Self.domainKey)
            return value
        }

        set {
            willChangeValue(forKey: Self.domainKey)
            primitiveDomain = newValue
            didChangeValue(forKey: Self.domainKey)
            updatePrimaryKey(remoteIdentifier: remoteIdentifier, domain: newValue)
        }
    }

    internal static let remoteIdentifierKey: String = "remoteIdentifier"
    @NSManaged private var primitiveRemoteIdentifier: String?
    // keep the same as objc non_specified for now
    @objc var remoteIdentifier: ConversationID! {
        get {
            willAccessValue(forKey: Self.remoteIdentifierKey)
            let value = transientUUID(forKey: Self.remoteIdentifierKey)
            didAccessValue(forKey: "remoteIdentifier")
            return value
        }

        set {
            willChangeValue(forKey: Self.remoteIdentifierKey)
            setTransientUUID(newValue, forKey: Self.remoteIdentifierKey)
            didChangeValue(forKey: Self.remoteIdentifierKey)
            updatePrimaryKey(remoteIdentifier: newValue, domain: domain)
        }
    }

    /// combination of domain and remoteIdentifier
    @NSManaged internal private(set) var primaryKey: String

    // MARK: - WireCells

    @NSManaged var cellName: String?
    @NSManaged var wireCellsMessageAttachmentDrafts: Set<WireCellsMessageAttachmentDraftEntity>

    private func updatePrimaryKey(remoteIdentifier: ConversationID?, domain: String?) {
        guard entity.attributesByName["primaryKey"] != nil else {
            // trying to access primaryKey property from older model - tests
            return
        }
        primaryKey = Self.primaryKey(from: remoteIdentifier, domain: domain)
    }

    /// Move message from otherConversation and other related properties
    func migrateMessages(from otherConversation: ZMConversation) {

        func assignIfNewer(newValue: inout Date?, oldValue: Date?) {
            if let timeStamp = oldValue, newValue?.compare(timeStamp) == .orderedAscending || newValue == nil {
                newValue = timeStamp
            }
        }

        mutableMessages.union(otherConversation.allMessages)

        assignIfNewer(
            newValue: &lastReadServerTimeStamp,
            oldValue: otherConversation.lastReadServerTimeStamp
        )

        assignIfNewer(
            newValue: &pendingLastReadServerTimestamp,
            oldValue: otherConversation.pendingLastReadServerTimestamp
        )

        assignIfNewer(
            newValue: &previousLastReadServerTimestamp,
            oldValue: otherConversation.previousLastReadServerTimestamp
        )

        assignIfNewer(
            newValue: &lastServerTimeStamp,
            oldValue: otherConversation.lastServerTimeStamp
        )

        assignIfNewer(
            newValue: &clearedTimeStamp,
            oldValue: otherConversation.clearedTimeStamp
        )

        assignIfNewer(
            newValue: &archivedChangedTimestamp,
            oldValue: otherConversation.archivedChangedTimestamp
        )

        assignIfNewer(
            newValue: &silencedChangedTimestamp,
            oldValue: otherConversation.silencedChangedTimestamp
        )
    }

}
