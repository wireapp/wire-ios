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
import WireSyncEngineSupport
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
    private var setAllowGuestAndServicesUseCase: MockSetAllowGuestAndServicesUseCaseProtocol!

    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - setUp

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        await syncContext.perform { [self] in
            setAllowGuestAndServicesUseCase = .init()
            setAllowGuestAndServicesUseCase
                .invokeConversationAllowGuestsAllowServicesCompletion_MockMethod = { _, _, _, completion in
                    completion(.success(()))
                }
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
        mockSelfUser = nil
        mockConversation = nil
        setAllowGuestAndServicesUseCase = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Helper Method

    private func configureRoleAndAccessForConversation(legacyAccessMode: Bool = false) {
        let role = Role.insertNewObject(in: syncContext)
        let action = Action.insertNewObject(in: syncContext)
        action.name = "modify_conversation_access"
        role.actions = [action]

        if legacyAccessMode {
            mockConversation.accessMode = [.invite]
        }

        mockConversation.addParticipantAndUpdateConversationState(user: mockSelfUser, role: role)
    }

    // MARK: - Unit Tests

    func testThatLinkGenerationSucceeds() async {
        await syncContext.perform { [self] in
            // GIVEN
            configureRoleAndAccessForConversation()

            let mockHandler = MockActionHandler<CreateConversationGuestLinkAction>(
                result: .success("www.test.com"),
                context: syncContext.notificationContext
            )

            let expectation = XCTestExpectation(description: "Guest link creation")

            sut.invoke(conversation: mockConversation, password: nil) { result in
                switch result {
                case let .success(link):
                    XCTAssertNotNil(link)
                case let .failure(error):
                    XCTFail("Test failed with error: \(error)")
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func testThatLinkGenerationSucceeds_LegacyMode() async {
        await syncContext.perform { [self] in
            // GIVEN
            configureRoleAndAccessForConversation(legacyAccessMode: true)

            let mockHandler = MockActionHandler<CreateConversationGuestLinkAction>(
                result: .success("www.test.com"),
                context: syncContext.notificationContext
            )
            let setGuestAndServicesMockHandler = MockActionHandler<SetAllowGuestsAndServicesAction>(
                result: .success(()),
                context: syncContext.notificationContext
            )

            let expectation = XCTestExpectation(description: "Guest link creation")

            sut.invoke(conversation: mockConversation, password: nil) { result in
                switch result {
                case let .success(link):
                    XCTAssertNotNil(link)
                case let .failure(error):
                    XCTFail("Test failed with error: \(error)")
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func testThatLinkGenerationFails() async {
        await syncContext.perform { [self] in

            let mockHandler = MockActionHandler<CreateConversationGuestLinkAction>(
                result: .failure(.unknown),
                context: syncContext.notificationContext
            )

            let expectation = XCTestExpectation(description: "completion should be called")

            sut.invoke(conversation: mockConversation, password: nil) { result in
                switch result {
                case .success:
                    XCTFail("Expected operation to fail, but it succeeded.")
                case .failure:
                    break
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }
}
