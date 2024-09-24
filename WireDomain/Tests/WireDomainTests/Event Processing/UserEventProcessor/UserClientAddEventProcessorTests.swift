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

import WireAPI
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import WireDomainSupport
import XCTest

final class UserClientAddEventProcessorTests: XCTestCase {

    var sut: UserClientAddEventProcessor!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!
    var userRepository: MockUserRepositoryProtocol!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        userRepository = MockUserRepositoryProtocol()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = UserClientAddEventProcessor(repository: userRepository)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        modelHelper = nil
        userRepository = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_User_Repo_Methods() async throws {
        // Given

        let event = UserClientAddEvent(
            client: UserClient(
                id: Scaffolding.clientID,
                type: .permanent,
                activationDate: .now,
                label: "test",
                model: "test",
                deviceClass: .phone,
                lastActiveDate: nil,
                mlsPublicKeys: nil,
                cookie: nil,
                capabilities: [.legalholdConsent]
            )
        )

        let selfUser = modelHelper.createSelfUser(in: context)
        let client = modelHelper.createClient(for: selfUser)

        // Mock

        userRepository.fetchOrCreateUserClientWith_MockMethod = { _ in (client, true) }
        userRepository.updateUserClientFromIsNewClient_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(userRepository.fetchOrCreateUserClientWith_Invocations.first, Scaffolding.clientID)
        XCTAssertEqual(userRepository.updateUserClientFromIsNewClient_Invocations.first?.remoteClient, event.client)
        XCTAssertEqual(userRepository.updateUserClientFromIsNewClient_Invocations.first?.localClient, client)
        XCTAssertEqual(userRepository.updateUserClientFromIsNewClient_Invocations.first?.isNewClient, true)
    }

    private enum Scaffolding {
        static let clientID = "94766bd92f56923d"
    }

}
