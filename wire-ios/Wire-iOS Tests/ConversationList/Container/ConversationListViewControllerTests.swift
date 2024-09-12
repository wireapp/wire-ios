//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import SnapshotTesting
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import Wire

// MARK: - MockConversationList

final class MockConversationList: ConversationListHelperType {
    static var hasArchivedConversations: Bool = false
}

// MARK: - MockConversationListDelegate

final class MockConversationListDelegate: ConversationListTabBarControllerDelegate {
    func didChangeTab(with type: TabBarItemType) {
        switch type {
        case .archive:
            self.archiveTabCallCount += 1
        case .startUI:
            self.startUITabCallCount += 1
        case .list:
            self.listTabCallCount += 1
        case .folder:
            self.folderTabCallCount += 1
        }
    }

    var startUITabCallCount: Int = 0
    var archiveTabCallCount: Int = 0
    var listTabCallCount: Int = 0
    var folderTabCallCount: Int = 0
}

// MARK: - ConversationListViewControllerTests

final class ConversationListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var sut: ConversationListViewController!
    var mockDelegate: MockConversationListDelegate!
    var userSession: UserSessionMock!
    private var coreDataFixture: CoreDataFixture!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue

        coreDataFixture = .init()

        userSession = .init()
        userSession.coreDataStack = coreDataFixture.coreDataStack

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        MockConversationList.hasArchivedConversations = false
        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            conversationListType: MockConversationList.self,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase
        )

        sut = ConversationListViewController(viewModel: viewModel)
        viewModel.viewController = sut
        sut.onboardingHint.arrowPointToView = sut.tabBar
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
        mockDelegate = MockConversationListDelegate()
        sut.delegate = self.mockDelegate
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        mockDelegate = nil
        userSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - View controller

    func testForNoConversations() {
        verify(matching: sut)
    }

    func testForEverythingArchived() {
        MockConversationList.hasArchivedConversations = true
        sut.showNoContactLabel(animated: false)

        verify(matching: sut)
    }

    // MARK: - PermissionDeniedViewController

    func testForPremissionDeniedViewController() {
        sut.showPermissionDeniedViewController()

        verify(matching: sut)
    }

    // MARK: - TabBar actions

    func testThatItCallsTheDelegateWhenTheContactsTabIsTapped() {
        // WHEN
        let item = UITabBarItem(type: .startUI)
        sut.tabBar(sut.tabBar, didSelect: item)

        // THEN
        XCTAssertEqual(mockDelegate.startUITabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheArchivedTabIsTapped() {
        // WHEN
        let item = UITabBarItem(type: .archive)
        sut.tabBar(sut.tabBar, didSelect: item)

        // THEN
        XCTAssertEqual(mockDelegate.archiveTabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheListTabIsTapped() {
        // WHEN
        let item = UITabBarItem(type: .list)
        sut.tabBar(sut.tabBar, didSelect: item)

        // THEN
        XCTAssertEqual(mockDelegate.listTabCallCount, 1)
    }

    func testThatItCallsTheDelegateWhenTheFolderTabIsTapped() {
        // WHEN
        let item = UITabBarItem(type: .folder)
        sut.tabBar(sut.tabBar, didSelect: item)

        // THEN
        XCTAssertEqual(mockDelegate.folderTabCallCount, 1)
    }

}
