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

    private var sut: UserClientAddEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        userRepository = MockUserRepositoryProtocol()
        sut = UserClientAddEventProcessor(
            repository: userRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        sut = nil
        userRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_User_Repo_Methods() async throws {
        // Mock

        let userClient = modelHelper.createSelfClient(in: context)

        userRepository.fetchOrCreateUserClientWith_MockMethod = { _ in
            (userClient, true)
        }

        userRepository.updateUserClientFromIsNewClient_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.fetchOrCreateUserClientWith_Invocations.count, 1)
        XCTAssertEqual(userRepository.updateUserClientFromIsNewClient_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = UserClientAddEvent(
            client: UserClient(
                id: "94766bd92f56923d",
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
    }

}
