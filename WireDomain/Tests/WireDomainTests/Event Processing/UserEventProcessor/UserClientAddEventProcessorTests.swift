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

final class UserClientAddEventProcessorTests: XCTestCase {

    var sut: UserClientAddEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = UserClientAddEventProcessor(
            repository: UserRepository(
                context: context,
                usersAPI: MockUsersAPI()
            )
        )
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testProcessEvent_It_Adds_A_Self_User_Client() async throws {
        // Given

        await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
            let selfUser = ZMUser.selfUser(in: context)
            XCTAssertEqual(selfUser.clients.count, 0)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            XCTAssertEqual(selfUser.clients.count, 1)

            let newClient = try XCTUnwrap(selfUser.clients.first)
            XCTAssertEqual(newClient.remoteIdentifier, Scaffolding.clientID)
        }
    }

    func testProcessEvent_It_Does_Not_Add_A_Self_User_Client_If_Client_Already_Exists() async throws {
        // Given

        await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
            modelHelper.createSelfClient(id: Scaffolding.clientID, in: context)
            let selfUser = ZMUser.selfUser(in: context)
            XCTAssertEqual(selfUser.clients.count, 1)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            XCTAssertEqual(selfUser.clients.count, 1)

            let existingClient = WireDataModel.UserClient.fetchExistingUserClient(
                with: Scaffolding.clientID,
                in: context
            )

            let newClient = try XCTUnwrap(selfUser.clients.first)
            XCTAssertEqual(newClient, existingClient)
        }
    }

}

private extension UserClientAddEventProcessorTests {
    enum Scaffolding {
        static let clientID = "94766bd92f56923d"

        static let event = UserClientAddEvent(
            client: UserClient(
                id: clientID,
                type: .permanent,
                activationDate: .now,
                label: "",
                model: "",
                deviceClass: .phone,
                lastActiveDate: nil,
                mlsPublicKeys: nil,
                cookie: nil,
                capabilities: [.legalholdConsent]
            )
        )
    }
}
