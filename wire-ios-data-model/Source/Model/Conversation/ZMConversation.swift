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

extension ZMConversation {
    /// Whether the conversation was deleted on the backend.

    @NSManaged public var isDeletedRemotely: Bool

    /// Whether the converstion is marked as read only

    @NSManaged public var isForcedReadOnly: Bool

    /// The other user of a one on one conversation.

    @NSManaged public var oneOnOneUser: ZMUser?

    /// True until the metadata has been fetched for the first time

    @NSManaged public var isPendingInitialFetch: Bool

    // MARK: - CoreData unique constraint

    static let domainKey = "domain"
    @NSManaged private var primitiveDomain: String?
    public var domain: String? {
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

    static let remoteIdentifierKey = "remoteIdentifier"
    @NSManaged private var primitiveRemoteIdentifier: String?
    // keep the same as objc non_specified for now
    @objc public var remoteIdentifier: UUID! {
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
    @NSManaged private var primaryKey: String

    private func updatePrimaryKey(remoteIdentifier: UUID?, domain: String?) {
        guard entity.attributesByName["primaryKey"] != nil else {
            // trying to access primaryKey property from older model - tests
            return
        }
        primaryKey = Self.primaryKey(from: remoteIdentifier, domain: domain)
    }
}
