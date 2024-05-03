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
import XCTest

@testable import WireSyncEngine

final class CreateConversationGuestLinkUseCaseTests: XCTestCase {

    // MARK: - Properties

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()
    private var mockConversation: ZMConversation!
    private var mockSelfUser: ZMUser!
    private var sut: CreateConversationGuestLinkUseCaseProtocol!
    private var setAllowGuestAndServicesUseCase: SetAllowGuestAndServicesUseCaseProtocol!

    private var syncContext: NSManagedObjectContext {
        return stack.syncContext
    }

    // MARK: - setUp

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        await syncContext.perform { [self] in
            setAllowGuestAndServicesUseCase = SetAllowGuestAndServicesUseCase()
            sut = CreateConversationGuestLinkUseCase(setGuestsAndServicesUseCase: setAllowGuestAndServicesUseCase)
            mockSelfUser = modelHelper.createSelfUser(in: syncContext)
            mockConversation = modelHelper.createGroupConversation(in: syncContext)
            mockConversation.teamRemoteIdentifier = UUID()
        }
    }

    // MARK: - tearDown

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Unit Tests

    func testThatLinkGenerationSucceeds() async {

        await syncContext.perform { [self] in
            // GIVEN
            let role = Role.insertNewObject(in: syncContext)
            let action = Action.insertNewObject(in: syncContext)
            role.name = "wire_admin"
            action.name = "modify_conversation_access"
            role.actions = [action]

            mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)

            let mockHandler = MockActionHandler<CreateConversationGuestLinkAction>(result: .success("www.test.com"), context: syncContext.notificationContext)

            let expectation = XCTestExpectation(description: "Guest link creation")

            sut.invoke(conversation: mockConversation, password: nil) { result in
                switch result {
                case .success(let link):
                    XCTAssertNotNil(link)
                case .failure(let error):
                    XCTFail("Test failed with error: \(error)")
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 4.0)
        }
    }

    func testThatLinkGenerationFails() async {

        await syncContext.perform { [self] in
            // GIVEN
            let role = Role.insertNewObject(in: syncContext)
            let action = Action.insertNewObject(in: syncContext)
            role.name = "wire_admin"
            action.name = "modify_conversation_access"
            role.actions = [action]

            mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)

            let mockHandler = MockActionHandler<CreateConversationGuestLinkAction>(result: .failure(.unknown), context: syncContext.notificationContext)

            let expectation = XCTestExpectation(description: "completion should be called")

            sut.invoke(conversation: mockConversation, password: nil) { result in
                switch result {
                case .success(let success):
                    XCTFail("Expected operation to fail, but it succeeded.")
                case .failure(let error):
                    print("Operation failed with \(error)")
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 4.0)
        }
    }

}
