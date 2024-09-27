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
import XCTest
@testable import Wire
@testable import WireDataModelSupport

final class ProfileViewControllerViewModelTests: XCTestCase {
    // MARK: Internal

    // MARK: - Setup & teardown

    override func setUp() async throws {
        try await super.setUp()

        let coreDataHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataHelper.createStack()

        user = MockUserType.createConnectedUser(name: "Cathy Jackson", inTeam: nil)
        oneToOneConversation = await viewContext.perform { ZMConversation.insertNewObject(in: self.viewContext) }
        mockUserSession = UserSessionMock()
        mockProfileActionsFactory = MockProfileActionsFactoryProtocol()

        mockViewModelDelegate = MockProfileViewControllerViewModelDelegate()
        mockViewModelDelegate.startAnimatingActivity_MockMethod = {}
        mockViewModelDelegate.stopAnimatingActivity_MockMethod = {}

        sut = ProfileViewControllerViewModel(
            user: user,
            conversation: nil,
            viewer: MockUserType.createSelfUser(name: "George Johnson", inTeam: nil),
            context: .profileViewer,
            classificationProvider: nil,
            userSession: mockUserSession,
            profileActionsFactory: mockProfileActionsFactory
        )

        sut.setDelegate(mockViewModelDelegate)
    }

    override func tearDown() {
        sut = nil
        mockProfileActionsFactory = nil
        mockViewModelDelegate = nil
        mockCoreDataStack = nil
        mockUserSession = nil
        user = nil
        oneToOneConversation = nil
        super.tearDown()
    }

    // MARK: - Open 1:1 conversation

    func test_OpenOneToOneConversation_TransitionsToConversation() {
        // Mock conversation
        user.oneToOneConversation = oneToOneConversation

        var transitionCount = 0
        sut.setConversationTransitionClosure { _ in
            transitionCount += 1
        }

        // When
        sut.openOneToOneConversation()

        // Then
        XCTAssertEqual(transitionCount, 1)
    }

    func test_OpenOneToOneConversation_CreatesConversation_WhenNoneExists() async {
        // Given
        // Mock conversation creation
        let expectation = XCTestExpectation(description: "completed conversation creation")
        mockUserSession.createTeamOneOnOneWithCompletion_MockMethod = { _, completion in
            completion(.success(self.oneToOneConversation))
            expectation.fulfill()
        }

        var transitionCount = 0
        sut.setConversationTransitionClosure { _ in
            transitionCount += 1
        }

        // When
        sut.openOneToOneConversation()

        // Then
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(mockUserSession.createTeamOneOnOneWithCompletion_Invocations.count, 1)
        XCTAssertEqual(transitionCount, 1)
    }

    // MARK: - Start 1:1 conversation

    func test_StartOneToOneConversation_Success() async {
        // Given
        // Mock conversation creation
        let expectation = XCTestExpectation(description: "completed conversation creation")
        mockUserSession.createTeamOneOnOneWithCompletion_MockMethod = { _, completion in
            completion(.success(self.oneToOneConversation))
            expectation.fulfill()
        }
        var transitionCount = 0
        sut.setConversationTransitionClosure { _ in
            transitionCount += 1
        }

        // When
        sut.startOneToOneConversation()

        // Then
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(mockViewModelDelegate.startAnimatingActivity_Invocations.count, 1)
        XCTAssertEqual(mockUserSession.createTeamOneOnOneWithCompletion_Invocations.count, 1)
        XCTAssertEqual(mockViewModelDelegate.stopAnimatingActivity_Invocations.count, 1)
        XCTAssertEqual(transitionCount, 1)
    }

    func test_StartOneToOneConversation_Failure() async {
        // Given
        // Mock conversation creation
        let expectation = XCTestExpectation(description: "completed conversation creation")
        mockUserSession.createTeamOneOnOneWithCompletion_MockMethod = { _, completion in
            completion(.failure(.userDoesNotExist))
            expectation.fulfill()
        }

        mockViewModelDelegate.presentConversationCreationErrorUsername_MockMethod = { _ in }

        // When
        sut.startOneToOneConversation()

        // Then
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(mockViewModelDelegate.startAnimatingActivity_Invocations.count, 1)
        XCTAssertEqual(mockUserSession.createTeamOneOnOneWithCompletion_Invocations.count, 1)
        XCTAssertEqual(mockViewModelDelegate.stopAnimatingActivity_Invocations.count, 1)
        XCTAssertEqual(mockViewModelDelegate.presentConversationCreationErrorUsername_Invocations.count, 1)
    }

    // MARK: - Update actions list

    func test_UpdateActionsList_UpdatesFooterActionsViews_OnCompletion() async {
        // Given
        let expectation = XCTestExpectation(description: "completed making actions list")
        mockProfileActionsFactory.makeActionsListCompletion_MockMethod = { completion in
            completion([.openOneToOne])
            expectation.fulfill()
        }

        mockViewModelDelegate.updateFooterActionsViews_MockMethod = { _ in }

        // When
        sut.updateActionsList()

        // Then
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(mockViewModelDelegate.updateFooterActionsViews_Invocations.first, [.openOneToOne])
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: ProfileViewControllerViewModel!
    private var mockProfileActionsFactory: MockProfileActionsFactoryProtocol!
    private var mockViewModelDelegate: MockProfileViewControllerViewModelDelegate!
    private var mockUserSession: UserSessionMock!
    private var mockCoreDataStack: CoreDataStack!
    private var user: MockUserType!
    private var oneToOneConversation: ZMConversation!

    private var viewContext: NSManagedObjectContext {
        mockCoreDataStack.viewContext
    }
}
