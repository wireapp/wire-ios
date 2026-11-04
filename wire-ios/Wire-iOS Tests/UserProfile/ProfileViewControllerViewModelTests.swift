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

import Foundation
import XCTest
@testable import Wire
@testable import WireDataModelSupport

final class ProfileViewControllerViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: ProfileViewControllerViewModel!
    private var mockProfileActionsFactory: MockProfileActionsFactoryProtocol!
    private var mockViewModelDelegate: MockProfileViewControllerViewModelDelegate!
    private var mockUserSession: UserSessionMock!
    private var mockCoreDataStack: CoreDataStack!
    private var user: MockUserType!
    private var oneToOneConversation: ZMConversation!
    private var contactability: Bool?
    private var contactStatusError: Error?

    private var viewContext: NSManagedObjectContext {
        mockCoreDataStack.viewContext
    }

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
        mockViewModelDelegate.updateContactStatusIsNonContactable_MockMethod = { _ in }

        sut = ProfileViewControllerViewModel(
            user: user,
            conversation: nil,
            viewer: MockUserType.createSelfUser(name: "George Johnson", inTeam: nil),
            context: .profileViewer,
            classificationProvider: nil,
            userSession: mockUserSession,
            profileActionsFactory: mockProfileActionsFactory,
            fetchContactability: { [weak self] in
                if let error = self?.contactStatusError { throw error }
                return self?.contactability
            }
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
        contactability = nil
        contactStatusError = nil
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
        await fulfillment(of: [expectation], timeout: 1)

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
        await fulfillment(of: [expectation], timeout: 1)

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
        await fulfillment(of: [expectation], timeout: 1)

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
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(mockViewModelDelegate.updateFooterActionsViews_Invocations.first, [.openOneToOne])
    }

    // MARK: - Contact status

    @MainActor
    func test_ContactStatus_NonContactableUserCannotStartConversation() async {
        contactability = false

        await sut.refreshContactStatus()
        sut.startOneToOneConversation()

        XCTAssertTrue(sut.isUserNonContactable)
        XCTAssertEqual(mockViewModelDelegate.updateContactStatusIsNonContactable_Invocations, [true])
        XCTAssertTrue(mockUserSession.createTeamOneOnOneWithCompletion_Invocations.isEmpty)
        XCTAssertTrue(mockViewModelDelegate.startAnimatingActivity_Invocations.isEmpty)
    }

    @MainActor
    func test_ContactStatus_RefreshCanRemoveRestriction() async {
        contactability = false
        await sut.refreshContactStatus()

        contactability = true
        await sut.refreshContactStatus()

        XCTAssertFalse(sut.isUserNonContactable)
        XCTAssertEqual(mockViewModelDelegate.updateContactStatusIsNonContactable_Invocations, [true, false])
    }

    @MainActor
    func test_ContactStatus_UnknownDoesNotRestrictUser() async {
        await sut.refreshContactStatus()

        XCTAssertFalse(sut.isUserNonContactable)
        XCTAssertEqual(mockViewModelDelegate.updateContactStatusIsNonContactable_Invocations, [false])
    }

    @MainActor
    func test_ContactStatus_FailedRefreshPreservesRestriction() async {
        contactability = false
        await sut.refreshContactStatus()

        contactStatusError = NSError(domain: "ContactStatusTests", code: 1)
        await sut.refreshContactStatus()

        XCTAssertTrue(sut.isUserNonContactable)
        XCTAssertEqual(mockViewModelDelegate.updateContactStatusIsNonContactable_Invocations, [true])
    }

    @MainActor
    func test_ContactStatus_CancelledRefreshDoesNotUpdateUI() async {
        contactability = false
        let task = Task { await sut.refreshContactStatus() }
        task.cancel()
        await task.value

        XCTAssertFalse(sut.isUserNonContactable)
        XCTAssertTrue(mockViewModelDelegate.updateContactStatusIsNonContactable_Invocations.isEmpty)
    }

}
