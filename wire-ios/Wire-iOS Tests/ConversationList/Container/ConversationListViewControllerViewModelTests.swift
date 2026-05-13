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
    private var mockGetUserAccountImageSourceUseCase: MockGetUserAccountImageSourceUseCaseProtocol!
    private var mockMainCoordinator: AnyMainCoordinator!

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())

        let account = Account.mockAccount(imageData: Data())
        selfUser = .createSelfUser(name: "Bob")
        userSession = UserSessionMock(mockUser: selfUser)

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        mockGetUserAccountImageSourceUseCase = .init()
        mockGetUserAccountImageSourceUseCase.invokeUserUserContextAccount_MockValue = .init()

        sut = ConversationListViewController.ViewModel(
            account: account,
            selfProfileViewsMonitor: MockSelfProfileViewsMonitorImplementation(didViewSelfProfile: false),
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            mainCoordinator: mockMainCoordinator,
            getUserAccountImageSourceUseCase: mockGetUserAccountImageSourceUseCase
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
        mockGetUserAccountImageSourceUseCase = nil
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

    func testSelectedFilterLabelReturnsEmptyStringForAllConversations() {
        XCTAssertEqual(ConversationListViewController.ViewModel.selectedFilterLabel(for: nil), "")
    }

    func testSelectedFilterLabelReturnsFolderNameForFolderFilter() {
        XCTAssertEqual(
            ConversationListViewController.ViewModel.selectedFilterLabel(
                for: .folder(id: UUID(), name: "Important")
            ),
            "Important"
        )
    }

    func testFilterHeaderDisplayStateIsHiddenForExpandedLayoutWithSelectedFilter() {
        let displayState = ConversationListViewController.ViewModel.filterHeaderDisplayState(
            mainSplitViewState: .expanded,
            selectedFilter: .favorites
        )

        XCTAssertTrue(displayState.isHidden)
        XCTAssertEqual(
            displayState.selectedFilterLabel,
            L10n.Localizable.ConversationList.Filter.Favorites.title
        )
    }

    func testFilterHeaderDisplayStateIsVisibleForCollapsedLayoutWithSelectedFilter() {
        let displayState = ConversationListViewController.ViewModel.filterHeaderDisplayState(
            mainSplitViewState: .collapsed,
            selectedFilter: .favorites
        )

        XCTAssertFalse(displayState.isHidden)
        XCTAssertEqual(
            displayState.selectedFilterLabel,
            L10n.Localizable.ConversationList.Filter.Favorites.title
        )
    }

    func testFilterHeaderDisplayStateIsHiddenForCollapsedLayoutWithoutFilter() {
        let displayState = ConversationListViewController.ViewModel.filterHeaderDisplayState(
            mainSplitViewState: .collapsed,
            selectedFilter: nil
        )

        XCTAssertTrue(displayState.isHidden)
        XCTAssertEqual(displayState.selectedFilterLabel, "")
    }

    func testNavigationBarUpdateMatchesSplitViewState() {
        XCTAssertEqual(
            ConversationListViewController.ViewModel.navigationBarUpdate(for: .collapsed),
            .collapsed
        )
        XCTAssertEqual(
            ConversationListViewController.ViewModel.navigationBarUpdate(for: .expanded),
            .expanded
        )
    }

    func testSearchPlaceholderTextReturnsFolderSpecificPlaceholder() {
        XCTAssertEqual(
            ConversationListViewController.ViewModel.searchPlaceholderText(
                for: .folder(id: UUID(), name: "Important")
            ),
            L10n.Localizable.ConversationList.SearchBar.foldersPlaceholder("Important")
        )
    }
}
