//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A pending legal hold client.

public class MockPendingLegalHoldClient: NSManagedObject {

    /// The user that received a legal hold request.
    @NSManaged public var user: MockUser?

    /// The identifier of the future client.
    @NSManaged public var identifier: String?

    /// Prekeys registered for this client
    @NSManaged public var prekeys: Set<MockPreKey>

    /// Last prekeys registered for this client
    @NSManaged public var lastPrekey: MockPreKey

}

public extension MockUser {

    /// Requests a legal hold for the user.
    func requestLegalHold() -> Bool {
        guard let managedObjectContext else {
            return false
        }

        guard memberships?.any(\.team.hasLegalHoldService) == true else {
            return false
        }

        let pendingClient = NSEntityDescription.insertNewObject(
            forEntityName: "PendingLegalHoldClient",
            into: managedObjectContext
        ) as! MockPendingLegalHoldClient

        pendingClient.user = self

        let identifier = String.randomClientIdentifier()
        pendingClient.identifier = identifier

        // Generate mock prekey strings
        let prekeysStrings = (0..<5).map { _ in UUID().uuidString }

        let prekeys = MockPreKey.insertNewKeys(
            withPayload: prekeysStrings,
            context: managedObjectContext
        )
        pendingClient.prekeys = Set(prekeys)

        let mockLastPrekey = NSEntityDescription.insertNewObject(
            forEntityName: "PreKey",
            into: managedObjectContext
        ) as! MockPreKey
        mockLastPrekey.identifier = Int(UInt16.max)
        mockLastPrekey.value = UUID().uuidString

        pendingClient.lastPrekey = mockLastPrekey
        return true
    }

    /// Accepts the legal hold for the user.
    func acceptLegalHold(with pendingClient: MockPendingLegalHoldClient) -> Bool {
        guard pendingClient == pendingLegalHoldClient else {
            return false
        }

        guard let managedObjectContext else {
            return false
        }

        let newClient = NSEntityDescription.insertNewObject(
            forEntityName: "UserClient",
            into: managedObjectContext
        ) as! MockUserClient

        newClient.user = self
        newClient.identifier = pendingClient.identifier
        newClient.label = "legalhold"
        newClient.type = "legalhold"
        newClient.deviceClass = "legalhold"
        newClient.time = Date()

        newClient.prekeys = pendingClient.prekeys
        newClient.lastPrekey = pendingClient.lastPrekey

        managedObjectContext.delete(pendingClient)
        return true
    }

}
