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
import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class UserUpdateEventProcessorTests: XCTestCase {

    var sut: UserUpdateEventProcessor!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = UserUpdateEventProcessor(
            repository: UserRepository(
                context: context,
                usersAPI: MockUsersAPI(),
                isFederationEnabled: true
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Updates_User_Locally() async throws {
        // Given

        modelHelper.createUser(id: Scaffolding.userID, in: context)

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let updatedUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(updatedUser.remoteIdentifier, Scaffolding.userID)
            XCTAssertEqual(updatedUser.domain, Scaffolding.domain)
            XCTAssertEqual(updatedUser.name, Scaffolding.event.name)
            XCTAssertEqual(updatedUser.handle, Scaffolding.event.handle)
            XCTAssertEqual(updatedUser.emailAddress, Scaffolding.event.email)
            XCTAssertEqual(updatedUser.supportedProtocols, [.proteus, .mls])
        }
    }

    private enum Scaffolding {
        static let userID = UUID()
        static let domain = "domain.com"

        nonisolated(unsafe) static let event = UserUpdateEvent(
            id: userID,
            userID: UserID(uuid: userID, domain: domain),
            accentColorID: nil,
            name: "username",
            handle: "test",
            email: "test@wire.com",
            isSSOIDDeleted: nil,
            assets: nil,
            supportedProtocols: [.proteus, .mls]
        )
    }

}
