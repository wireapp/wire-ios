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

final class SetAllowGuestsAndServicesUseCaseTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()
    private var mockConversation: ZMConversation!
    private var mockSelfUser: ZMUser!
    private var sut: SetAllowGuestAndServicesUseCaseProtocol!

    private var syncContext: NSManagedObjectContext {
        return stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        await syncContext.perform { [self] in
            sut = SetAllowGuestAndServicesUseCase()
            mockSelfUser = modelHelper.createSelfUser(in: syncContext)
            mockConversation = modelHelper.createGroupConversation(in: syncContext)
            mockConversation.teamRemoteIdentifier = UUID()
        }
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testGuestEnablementSucceeds() async {

        await syncContext.perform { [self] in
            // GIVEN
            let role = Role.insertNewObject(in: syncContext)
            let action = Action.insertNewObject(in: syncContext)
            action.name = "modify_conversation_access"
            role.actions = [action]

            mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)

            let mockHandler = MockActionHandler<SetAllowGuestsAndServicesAction>(result: .success(()), context: syncContext.notificationContext)

            let expectation = XCTestExpectation(description: "completion should be called")

            // WHEN
            sut.invoke(conversation: mockConversation, allowGuests: true, allowServices: false) { result in
                // THEN
                switch result {
                case .success:
                    print("Operation successful")
                case .failure(let error):
                    XCTFail("Test failed with error: \(error)")
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.4)
        }
    }

    func testGuestEnablementFails_WithInsufficientPermissions() async {
        await syncContext.perform { [self] in
            // GIVEN
            let mockHandler = MockActionHandler<SetAllowGuestsAndServicesAction>(result: .failure(.unknown), context: syncContext.notificationContext)

            let expectation = XCTestExpectation(description: "Completion should be called with a failure due to insufficient permissions")

            // WHEN
            sut.invoke(conversation: mockConversation, allowGuests: true, allowServices: false) { result in
                // THEN
                switch result {
                case .success:
                    XCTFail("Expected operation to fail, but it succeeded.")
                case .failure(let error):
                    break
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.4)
        }
    }

    func testServicesEnablementSucceeds() async {

        await syncContext.perform { [self] in
            // GIVEN
            let role = Role.insertNewObject(in: syncContext)
            let action = Action.insertNewObject(in: syncContext)
            action.name = "modify_conversation_access"
            role.actions = [action]

            mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)

            let mockHandler = MockActionHandler<SetAllowGuestsAndServicesAction>(result: .success(()), context: syncContext.notificationContext)

            let expectation = XCTestExpectation(description: "completion should be called")

            // WHEN
            sut.invoke(conversation: mockConversation, allowGuests: false, allowServices: true) { result in
                // THEN
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail("Test failed with error: \(error)")
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.4)
        }
    }

    func testServicesEnablementFails_WithInsufficientPermissions() async {

        await syncContext.perform { [self] in
            // GIVEN
            let mockHandler = MockActionHandler<SetAllowGuestsAndServicesAction>(result: .failure(.unknown), context: syncContext.notificationContext)
            let expectation = XCTestExpectation(description: "Completion should be called with a failure due to insufficient permissions")

            // WHEN
            sut.invoke(conversation: mockConversation, allowGuests: false, allowServices: true) { result in
                // THEN
                switch result {
                case .success:
                    XCTFail("Expected operation to fail, but it succeeded.")
                case .failure:
                    break
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.4)
        }
    }

}
