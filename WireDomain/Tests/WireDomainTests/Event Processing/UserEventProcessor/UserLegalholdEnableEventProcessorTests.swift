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

final class UserLegalHoldEnableEventProcessorTests: XCTestCase {

    private var sut: UserLegalholdEnableEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!
    private var clientRepository: MockClientRepositoryProtocol!
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
        clientRepository = MockClientRepositoryProtocol()
        sut = UserLegalholdEnableEventProcessor(
            context: context,
            userRepository: userRepository,
            clientRepository: clientRepository
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
        clientRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_Methods() async throws {
        // Mock

        let (selfUser, selfClient) = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID,
                domain: nil,
                in: context
            )

            let selfClient = modelHelper.createSelfClient(
                id: Scaffolding.deletedUserClientID.uuidString,
                in: context
            )

            return (selfUser, selfClient)
        }

        userRepository.fetchSelfUser_MockValue = selfUser
        clientRepository.fetchSelfClients_MockValue = [
            Scaffolding.userClient1,
            Scaffolding.userClient2,
            Scaffolding.userClient3
        ]
        clientRepository.updateClientWithFromIsNewClient_MockMethod = { _, _, _ in }
        clientRepository.fetchOrCreateClientWith_MockValue = (selfClient, true)
        clientRepository.deleteClientWith_MockMethod = { _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.fetchSelfUser_Invocations.count, 2)
        XCTAssertEqual(clientRepository.fetchSelfClients_Invocations.count, 1)
        XCTAssertEqual(clientRepository.updateClientWithFromIsNewClient_Invocations.count, 3)
        XCTAssertEqual(clientRepository.fetchOrCreateClientWith_Invocations.count, 3)
        XCTAssertEqual(clientRepository.deleteClientWith_Invocations.count, 1)
        XCTAssertEqual(clientRepository.deleteClientWith_Invocations, [Scaffolding.deletedUserClientID.uuidString])
    }

    private enum Scaffolding {
        static let selfUserID = UUID()

        static let event = UserLegalholdEnableEvent(
            userID: selfUserID
        )

        static let deletedUserClientID = UUID()

        static let userClient1 = WireAPI.UserClient(
            id: UUID().uuidString,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        static let userClient2 = WireAPI.UserClient(
            id: UUID().uuidString,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        static let userClient3 = WireAPI.UserClient(
            id: UUID().uuidString,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )
    }

}
