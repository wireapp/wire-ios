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

import WireTestingPackage
import XCTest

@testable import Wire
@testable import WireSyncEngineSupport

final class ProfileViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: ProfileViewController!
    private var mockUser: MockUser!
    private var selfUser: MockUser!
    private var mockViewModel: MockProfileViewControllerViewModeling!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .blue
        snapshotHelper = SnapshotHelper()
        let teamIdentifier = UUID()
        selfUser = MockUser.createSelfUser(name: "George Johnson", inTeam: teamIdentifier)
        selfUser.handle = "georgejohnson"
        selfUser.feature(withUserClients: 6)

        mockUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: teamIdentifier)
        mockUser.handle = "catherinejackson"
        mockUser.emailAddress = "catherinejackson@mail.com"
        mockUser.domain = "domain.com"
        mockUser.feature(withUserClients: 6)

        mockViewModel = MockProfileViewControllerViewModeling()
        mockViewModel.viewer = selfUser
        mockViewModel.user = mockUser
        mockViewModel.userSession = UserSessionMock()
        mockViewModel.hasUserClientListTab = false
        mockViewModel.incomingRequestFooterHidden = true
        mockViewModel.hasLegalHoldItem = false
        mockViewModel.updateActionsList_MockMethod = { }
        mockViewModel.context = .profileViewer
        mockViewModel.setDelegate_MockMethod = { _ in }
        mockViewModel.setConversationTransitionClosure_MockMethod = { _ in }
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockUser = nil
        selfUser = nil
        mockViewModel = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    @MainActor
    func test_ProfileInfo() {
        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_UserWithoutName() {
        // GIVEN
        mockUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        mockUser.name = nil
        mockUser.domain = "foma.wire.link"
        mockUser.initials = ""
        mockViewModel.user = mockUser

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_WithLegalHold_InNavigationController() {
        // GIVEN
        mockViewModel.hasLegalHoldItem = true

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        snapshotHelper.verify(matching: navWrapperController)
    }

    @MainActor
    func test_ProfileInfo_BottomAction_OpenOneToOne() {
        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.openOneToOne])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_BottomAction_OpenSelfProfile() {
        // GIVEN
        mockViewModel.user = selfUser

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.openSelfProfile])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_BottomAction_RemoveFromGroup() {
        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.removeFromGroup])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_BottomAction_Multiple() {
        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.openOneToOne, .block(isBlocked: false)])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_HasClientListTab_IncomingRequest() {
        // GIVEN
        mockViewModel.hasUserClientListTab = true
        mockViewModel.incomingRequestFooterHidden = false
        mockUser.teamIdentifier = nil
        mockUser.emailAddress = nil
        mockUser.domain = nil

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_HasClientListTab_IncomingRequest_Classified() {
        // GIVEN
        mockViewModel.hasUserClientListTab = true
        mockViewModel.incomingRequestFooterHidden = false
        mockViewModel.classification = .classified
        mockUser.teamIdentifier = nil
        mockUser.emailAddress = nil
        mockUser.domain = nil

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_HasClientListTab_IncomingRequest_NotClassified() {
        // GIVEN
        mockViewModel.hasUserClientListTab = true
        mockViewModel.incomingRequestFooterHidden = false
        mockViewModel.classification = .notClassified
        mockUser.teamIdentifier = nil
        mockUser.emailAddress = nil
        mockUser.domain = nil

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_ProfileInfo_NonTeamMember_BottomAction_Connect() {
        // GIVEN
        mockUser.teamIdentifier = nil
        mockUser.emailAddress = nil
        mockUser.domain = nil

        // Setting up the user to show the `WarningLabelView`
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.isConnected = false
        mockUser.isTeamMember = false

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.connect])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_OneToOneContext_HasClientListTab_BottomAction_CreateGroup() {
        // GIVEN
        mockViewModel.hasUserClientListTab = true
        mockViewModel.context = .oneToOneConversation

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)
        sut.updateFooterActionsViews([.createGroup])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func test_DeviceListContext_HasClientListTab() {
        // GIVEN
        mockViewModel.hasUserClientListTab = true
        mockViewModel.context = .deviceList

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Data Refresh tests

    @MainActor
    func testItRequestsDataRefeshForTeamMembers() {
        // GIVEN
        mockUser.isTeamMember = true

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        XCTAssertEqual(mockUser.refreshDataCount, 1)
        XCTAssertEqual(mockUser.refreshMembershipCount, 1)
    }

    @MainActor
    func testItDoesNotRequestsDataRefeshForNonTeamMembers() {
        // GIVEN
        mockUser.isTeamMember = false

        // WHEN
        sut = ProfileViewController(viewModel: mockViewModel, mainCoordinator: .mock)

        // THEN
        XCTAssertEqual(mockUser.refreshMembershipCount, 0)
    }
}
