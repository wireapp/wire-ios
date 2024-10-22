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

@testable import Wire
@testable import WireDataModelSupport

final class ConversationListViewControllerViewModelTests: XCTestCase {

    private var sut: ConversationListViewController.ViewModel!
    private var mockViewController: MockConversationListContainer!
    private var selfUser: MockUserType!
    private var mockConversation: ZMConversation!
    private var userSession: UserSessionMock!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var mockGetUserAccountImageUseCase: MockGetUserAccountImageUseCase!
    private var mockMainCoordinator: MainCoordinator!

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())

        let account = Account.mockAccount(imageData: Data())
        selfUser = .createSelfUser(name: "Bob")
        userSession = UserSessionMock(mockUser: selfUser)

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        mockGetUserAccountImageUseCase = .init()
        mockGetUserAccountImageUseCase.invoke_MockValue = .init()

        sut = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            mainCoordinator: mockMainCoordinator,
            getUserAccountImageUseCase: mockGetUserAccountImageUseCase
        )
        mockViewController = MockConversationListContainer(viewModel: sut)
        sut.viewController = mockViewController
    }

    override func tearDown() {
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        mockViewController = nil
        selfUser = nil
        mockConversation = nil
        userSession = nil
        mockGetUserAccountImageUseCase = nil
        mockMainCoordinator = nil
    }

    func testThatSelectAConversationCallsSelectOnListContentController() {
        // GIVEN
        XCTAssertFalse(mockViewController.isSelectedOnListContentController)

        // WHEN
        mockConversation = ZMConversation()
        sut.select(conversation: mockConversation)

        // THEN
        XCTAssertEqual(mockConversation, sut.selectedConversation)
        XCTAssert(mockViewController.isSelectedOnListContentController)
    }
}
