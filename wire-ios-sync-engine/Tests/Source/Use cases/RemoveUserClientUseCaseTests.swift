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

@testable import WireSyncEngineSupport
@testable import WireDataModelSupport
@testable import WireRequestStrategySupport
import XCTest

final class RemoveUserClientUseCaseTests: XCTestCase {

    private var sut: RemoveUserClientUseCase!
    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    var mockApiProvider: MockAPIProviderInterface!
    let messageApi = MockMessageAPI()

    override func setUp() async throws {
        try await super.setUp()

        mockApiProvider = MockAPIProviderInterface()
        stack = try await coreDataStackHelper.createStack()
        sut = RemoveUserClientUseCase(
            apiProvider: mockApiProvider,
            syncContext: stack.syncContext)

    }

    override func tearDown() async throws {
        mockApiProvider = nil
        stack = nil
        sut = nil

        try await super.tearDown()
    }

    func testThatItRemovesUserClient() async throws {
        // Given
        var userClient: UserClient!
        let clientID1 = MLSClientID.random()
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        try await stack.syncContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.syncContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            userClient = modelHelper.createClient(id: clientID1.clientID, for: selfUser)

            try self.stack.syncContext.save()
        }

        // When
        let expectation = XCTestExpectation(description: "should call deleteUserClient")
        let userClientAPI = MockUserClientAPI()
        userClientAPI.deleteUserClientClientIdCredentials_MockMethod = {_, _ in
            // Then
            expectation.fulfill()
        }
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI

        try await sut.invoke(userClient, credentials: EmailCredentials(email: "", password: ""))
    }

    func testThatItDoesNotRemoveUserClient_WhenClientDoesNotExistLocally() async throws {
        // Given
        var userClient: UserClient!
        let clientID1 = MLSClientID.random()
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        await stack.viewContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.viewContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            userClient = modelHelper.createClient(id: clientID1.clientID, for: selfUser)
        }

        let userClientAPI = MockUserClientAPI()
        userClientAPI.deleteUserClientClientIdCredentials_MockMethod = { _, _ in }
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI

        // When / Then
        await assertItThrows(error: RemoveUserClientError.clientDoesNotExistLocally) {
            try await sut.invoke(userClient, credentials: EmailCredentials(email: "", password: ""))
        }
    }

    func testThatItDoesNotRemoveUserClient_WhenClientDoesNotExistRemotely() async throws {
        // Given
        var userClient: UserClient!
        let clientID1 = MLSClientID.random()
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        try await stack.syncContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.syncContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            userClient = modelHelper.createClient(id: clientID1.clientID, for: selfUser)

            try self.stack.syncContext.save()
        }

        let userClientAPI = MockUserClientAPI()
        userClientAPI.deleteUserClientClientIdCredentials_MockMethod = { _, _ in }
        userClientAPI.deleteUserClientClientIdCredentials_MockError = RemoveUserClientError.clientToDeleteNotFound
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI

        // When / Then
        await assertItThrows(error: RemoveUserClientError.clientToDeleteNotFound) {
            try await sut.invoke(userClient, credentials: EmailCredentials(email: "", password: ""))
        }
    }

    func testThatItDoesNotRemoveUserClient_WhenInvalidCredentials() async throws {
        // Given
        var userClient: UserClient!
        let clientID1 = MLSClientID.random()
        let selfUserHandle = "foo"
        let selfUserName = "Ms Foo"
        let domain = "local.com"
        try await stack.syncContext.perform {
            let modelHelper = ModelHelper()

            let selfUser = modelHelper.createSelfUser(in: self.stack.syncContext)
            selfUser.handle = selfUserHandle
            selfUser.name = selfUserName
            selfUser.domain = domain

            userClient = modelHelper.createClient(id: clientID1.clientID, for: selfUser)

            try self.stack.syncContext.save()
        }

        let userClientAPI = MockUserClientAPI()
        userClientAPI.deleteUserClientClientIdCredentials_MockMethod = { _, _ in }
        userClientAPI.deleteUserClientClientIdCredentials_MockError = RemoveUserClientError.invalidCredentials
        mockApiProvider.userClientAPIApiVersion_MockValue = userClientAPI

        // When / Then
        await assertItThrows(error: RemoveUserClientError.invalidCredentials) {
            try await sut.invoke(userClient, credentials: EmailCredentials(email: "", password: ""))
        }
    }

}
