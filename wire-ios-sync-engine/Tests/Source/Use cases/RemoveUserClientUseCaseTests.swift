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

import XCTest
@testable import WireDataModelSupport
@testable import WireRequestStrategySupport
@testable import WireSyncEngine

final class RemoveUserClientUseCaseTests: XCTestCase {
    private var sut: RemoveUserClientUseCase!
    private var stack: CoreDataStack!
    private let coreDataStackHelper = CoreDataStackHelper()
    private let mockApiProvider = MockAPIProviderInterface()
    private let userClientAPI = MockUserClientAPI()

    override func setUp() async throws {
        try await super.setUp()

        stack = try await coreDataStackHelper.createStack()
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI
        sut = RemoveUserClientUseCase(
            userClientAPI: mockApiProvider.userClientAPIApiVersion_MockValue!,
            syncContext: stack.syncContext
        )
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil

        try await super.tearDown()
    }

    func testThatItRemovesUserClient() async throws {
        // Given
        let clientId = "222"
        try await createSelfClient(clientId: clientId)
        let expectation = XCTestExpectation(description: "should call deleteUserClient")
        userClientAPI.deleteUserClientClientIdPassword_MockMethod = { _, _ in
            // Then
            expectation.fulfill()
        }
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI

        // When
        try await sut.invoke(clientId: clientId, password: "")
    }

    func testThatItDoesNotRemoveUserClient_WhenClientDoesNotExistLocally() async throws {
        // Given
        userClientAPI.deleteUserClientClientIdPassword_MockMethod = { _, _ in }

        // When / Then
        await assertItThrows(error: RemoveUserClientError.clientDoesNotExistLocally) {
            try await sut.invoke(clientId: "", password: "")
        }
    }

    func testThatItDoesNotRemoveUserClient_WhenClientDoesNotExistRemotely() async throws {
        // Given
        let clientId = "222"
        try await createSelfClient(clientId: clientId)
        userClientAPI.deleteUserClientClientIdPassword_MockMethod = { _, _ in }
        userClientAPI.deleteUserClientClientIdPassword_MockError = RemoveUserClientError.clientToDeleteNotFound

        // When / Then
        await assertItThrows(error: RemoveUserClientError.clientToDeleteNotFound) {
            try await sut.invoke(clientId: clientId, password: "")
        }
    }

    func testThatItDoesNotRemoveUserClient_WhenInvalidCredentials() async throws {
        // Given
        let clientId = "222"
        try await createSelfClient(clientId: clientId)
        userClientAPI.deleteUserClientClientIdPassword_MockMethod = { _, _ in }
        userClientAPI.deleteUserClientClientIdPassword_MockError = RemoveUserClientError.invalidCredentials

        // When / Then
        await assertItThrows(error: RemoveUserClientError.invalidCredentials) {
            try await sut.invoke(clientId: clientId, password: "")
        }
    }

    private func createSelfClient(clientId: String) async throws {
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        try await stack.syncContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.syncContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            _ = modelHelper.createClient(id: clientId, for: selfUser)

            try self.stack.syncContext.save()
        }
    }
}
