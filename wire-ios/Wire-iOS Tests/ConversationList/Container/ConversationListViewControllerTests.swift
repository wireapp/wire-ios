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

import SnapshotTesting
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import Wire

// MARK: - MockConversationList

final class MockConversationList: ConversationListHelperType {
    static var hasArchivedConversations: Bool = false
}

// MARK: - ConversationListViewControllerTests

final class ConversationListViewControllerTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: ConversationListViewController!
    var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .blue

        userSession = UserSessionMock()

        MockConversationList.hasArchivedConversations = false
        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            conversationListType: MockConversationList.self,
            userSession: userSession
        )

        sut = ConversationListViewController(
            viewModel: viewModel,
            selfProfileViewControllerBuilder: .mock,
            settingsViewControllerBuilder: .mock
        )
        viewModel.viewController = sut
        sut.onboardingHint.arrowPointToView = sut.tabBar
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        userSession = nil

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
}
