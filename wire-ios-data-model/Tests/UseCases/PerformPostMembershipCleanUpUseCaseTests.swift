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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireDataModel

final class PerformPostMembershipCleanUpUseCaseTests: XCTestCase {

    private var teamID: UUID!
    private var coreDataStack: CoreDataStack!
    private var context: NSManagedObjectContext { coreDataStack.syncContext }

    override func setUp() async throws {
        teamID = UUID()
        coreDataStack = try await CoreDataStackHelper().createStack()

        try await context.perform { [self, context] in
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.teamIdentifier = teamID
            print(selfUser.objectID.uriRepresentation())
            try context.save()
        }
    }

    override func tearDown() {
        teamID = nil
        coreDataStack = nil
    }

    func testInvoke_whenUserIDDoesNotExist() throws {
        // Given
        let sut = PerformPostMembershipCleanUpUseCase(context: context, userID: try missingUserID())

        // When, Then
        XCTAssertThrowsError(try sut.invoke())
    }

    func testInvoke_whenUserIDNotSet() throws {
        // Given
        try context.performAndWait { [context] in
            let data: [(userName: String, connectionStatus: ZMConnectionStatus)] = [
                ("A", .invalid),
                ("B", .accepted),
                ("C", .pending),
                ("D", .ignored),
                ("E", .blocked),
                ("F", .sent),
                ("G", .cancelled),
                ("H", .blockedMissingLegalholdConsent)
            ]

            for (userName, connectionStatus) in data {
                let user = ZMUser(context: context)
                user.name = userName
                user.teamIdentifier = teamID

                let connection = ZMConnection(context: context)
                connection.status = connectionStatus
                connection.to = user
            }

            try context.save()
        }
        let sut = PerformPostMembershipCleanUpUseCase(context: context, userID: nil)

        // When
        try sut.invoke()

        // Then
        try context.performAndWait { [context] in
            let request = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
            let connections = try context.fetch(request)

            XCTAssertEqual(connections.count, 2)
            XCTAssertEqual(connections.map { $0.to.name! }.sorted(), ["B", "E"])

        }
    }

    // MARK: Helpers

    private func missingUserID() throws -> NSManagedObjectID {
        try context.performAndWait { [context] in
            let tempUser = ZMUser(context: context)
            let invalidUserID = tempUser.objectID
            context.delete(tempUser)
            try context.save()
            return invalidUserID
        }
    }
}
