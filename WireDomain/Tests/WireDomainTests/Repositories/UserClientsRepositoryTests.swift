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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class UserClientsRepositoryTests: XCTestCase {

    private var sut: UserClientsRepository!
    private var userClientsAPI: MockUserClientsAPI!
    private var userRepository: MockUserRepositoryProtocol!
    private var userClientsLocalStore: MockUserClientsLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        userClientsAPI = MockUserClientsAPI()
        userRepository = MockUserRepositoryProtocol()
        userClientsLocalStore = MockUserClientsLocalStoreProtocol()

        sut = UserClientsRepository(
            userClientsAPI: userClientsAPI,
            userRepository: userRepository,
            userClientsLocalStore: userClientsLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        userClientsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testFetchOrCreateClient_It_Invokes_Local_Store_Method() async throws {
        // Mock

        let userClient = await context.perform { [self] in
            return modelHelper.createSelfClient(
                id: Scaffolding.userClientID,
                in: context
            )
        }

        userClientsLocalStore.fetchOrCreateClientId_MockValue = (userClient, false)

        // When

        _ = try await sut.fetchOrCreateClient(
            id: Scaffolding.userClientID
        )

        // Then

        XCTAssertEqual(userClientsLocalStore.fetchOrCreateClientId_Invocations.count, 1)
    }

    func testUpdateClient_It_Invokes_Local_Store_Method() async throws {
        // Mock

        userClientsLocalStore.updateClientIdIsNewClientUserClientInfo_MockMethod = { _, _, _ in }

        // When

        await sut.updateClient(
            id: Scaffolding.userClientID,
            from: Scaffolding.selfUserClient,
            isNewClient: false
        )

        // Then

        XCTAssertEqual(userClientsLocalStore.updateClientIdIsNewClientUserClientInfo_Invocations.count, 1)
    }

    func testPullSelfClients_It_Invokes_Local_Store_And_User_Repo_Methods() async throws {
        // Mock

        let selfUserClient = await context.perform { [self] in
            return modelHelper.createSelfClient(
                id: Scaffolding.otherUserClientID,
                in: context
            )
        }

        userClientsAPI.getSelfClients_MockValue = [
            Scaffolding.selfUserClient
        ]

        userClientsLocalStore.fetchOrCreateClientId_MockValue = (selfUserClient, false)
        userClientsLocalStore.updateClientIdIsNewClientUserClientInfo_MockMethod = { _, _, _ in }
        userClientsLocalStore.deletedSelfClientsNewClients_MockValue = [Scaffolding.userClientID]
        userClientsLocalStore.deleteClientId_MockMethod = { _ in }

        // When

        try await sut.pullSelfClients()

        // Then

        XCTAssertEqual(userClientsLocalStore.fetchOrCreateClientId_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.updateClientIdIsNewClientUserClientInfo_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.deletedSelfClientsNewClients_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.deleteClientId_Invocations.count, 1)
    }

    func testDeleteClient_It_Invokes_Local_Store_Method() async throws {
        // Mock

        userClientsLocalStore.deleteClientId_MockMethod = { _ in }

        // When

        await sut.deleteClient(id: Scaffolding.userClientID)

        // Then

        XCTAssertEqual(userClientsLocalStore.deleteClientId_Invocations.count, 1)
    }

    func testInvalidSelfClient_It_Invokes_Local_Store_Method() async throws {
        // Mock

        userClientsLocalStore.invalidateSelfClient_MockMethod = {}

        // When

        await sut.invalidateSelfClient()

        // Then

        XCTAssertEqual(userClientsLocalStore.invalidateSelfClient_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let userClientID = UUID.mockID1.uuidString
        static let otherUserClientID = UUID.mockID2.uuidString

        static let selfUserClient = WireNetwork.SelfUserClient(
            id: userClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )
    }

}
