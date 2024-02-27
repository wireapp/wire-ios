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
import XCTest
@testable import Wire

final class ProfileViewControllerTests: BaseSnapshotTestCase {

    // MARK: - Properties

    private var sut: ProfileViewController!
    private var mockUser: MockUser!
    private var selfUser: MockUser!
    private var userSession: UserSessionMock!
    private var teamIdentifier: UUID!
    private var mockClassificationProvider: MockClassificationProvider!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        userSession = UserSessionMock()
        teamIdentifier = UUID()
        selfUser = MockUser.createSelfUser(name: "George Johnson", inTeam: teamIdentifier)
        selfUser.handle = "georgejohnson"
        selfUser.feature(withUserClients: 6)

        mockUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: teamIdentifier)
        mockUser.handle = "catherinejackson"
        mockUser.feature(withUserClients: 6)

        mockClassificationProvider = MockClassificationProvider()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockUser = nil
        selfUser = nil
        userSession = nil
        teamIdentifier = nil
        mockClassificationProvider = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    // MARK: - .profileViewer  Context

    func testForContextProfileViewer() {
        // GIVEN
        selfUser.teamRole = .member
        mockUser.emailAddress = nil

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForContextProfileViewerForSelfUser() {
        // GIVEN
        selfUser.teamRole = .member
        selfUser.emailAddress = nil

        // WHEN
        sut = ProfileViewController(
            user: selfUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForUserName() {
        // GIVEN
        selfUser.teamRole = .member
        selfUser.emailAddress = nil
        selfUser.availability = .busy
        selfUser.isTrusted = true

        // WHEN
        sut = ProfileViewController(
            user: selfUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    func testForContextProfileViewerUnderLegalHold() {
        // GIVEN
        selfUser.teamRole = .member
        mockUser.emailAddress = nil
        mockUser.isUnderLegalHold = true

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    func testForContextProfileViewerUnderLegalHold_WithSelfUserOutsideTeam() {
        // GIVEN
        let selfUserOutsideTeam = MockUser.createSelfUser(name: "John Johnson", inTeam: nil)
        selfUserOutsideTeam.handle = "johnjohnson"
        selfUserOutsideTeam.feature(withUserClients: 6)

        mockUser.emailAddress = nil
        mockUser.isUnderLegalHold = true

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUserOutsideTeam,
            context: .profileViewer,
            userSession: userSession
        )
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    func testForContextProfileViewerForSelfUserUnderLegalHold() {
        // GIVEN
        selfUser.teamRole = .member
        selfUser.emailAddress = nil
        selfUser.isUnderLegalHold = true

        // WHEN
        sut = ProfileViewController(
            user: selfUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    func testForContextProfileViewer_ForUserWithoutName() {
        // GIVEN
        selfUser.teamRole = .member
        mockUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        mockUser.name = nil
        mockUser.domain = "foma.wire.link"
        mockUser.initials = ""

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    func testItRequestsDataRefeshForTeamMembers() {
        // GIVEN
        mockUser.isTeamMember = true

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )

        // THEN
        XCTAssertEqual(mockUser.refreshDataCount, 1)
        XCTAssertEqual(mockUser.refreshMembershipCount, 1)
    }

    func testItDoesNotRequestsDataRefeshForNonTeamMembers() {
        // GIVEN
        mockUser.isTeamMember = false

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )

        // THEN
        XCTAssertEqual(mockUser.refreshMembershipCount, 0)
    }

    // MARK: - .deviceList  Context

    func testForDeviceListContext() {
        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .deviceList,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForWrapInNavigationController() {
        // GIVEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .deviceList,
            userSession: userSession
        )

        // WHEN
        let navWrapperController = sut.wrapInNavigationController()
        sut.viewDidAppear(false)

        // THEN
        verify(matching: navWrapperController)
    }

    // MARK: - .oneToOneConversation  Context

    func testForContextOneToOneConversation() {
        // GIVEN
        let selfUser = MockUserType.createSelfUser(name: "Bob", inTeam: UUID())
        mockUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .oneToOneConversation,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForContextOneToOneConversationForPartnerRole() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canCreateConversation = false
        mockUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .oneToOneConversation,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    // MARK: - .groupConversation  Context

    func testForIncomingRequest() {
        // GIVEN
        mockUser.isConnected = false
        mockUser.canBeConnected = true
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.emailAddress = nil
        mockUser.teamIdentifier = nil

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .groupConversation,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForIncomingRequestFromClassifiedUser() {
        // GIVEN
        mockUser.isConnected = false
        mockUser.canBeConnected = true
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.emailAddress = nil
        mockUser.teamIdentifier = nil

        mockClassificationProvider.returnClassification = .classified

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .groupConversation,
            classificationProvider: mockClassificationProvider,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForIncomingRequestFromNotClassifiedUser() {
        // GIVEN
        mockUser.isConnected = false
        mockUser.canBeConnected = true
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.emailAddress = nil
        mockUser.teamIdentifier = nil

        mockClassificationProvider.returnClassification = .notClassified

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .groupConversation,
            classificationProvider: mockClassificationProvider,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForIncomingRequestFromNotTeamMember() {
        // GIVEN
        mockUser.isConnected = false
        mockUser.canBeConnected = true
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.emailAddress = nil
        mockUser.teamIdentifier = nil
        mockUser.isTeamMember = false

        mockClassificationProvider.returnClassification = .classified

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            conversation: conversation.convertToRegularConversation(),
            context: .groupConversation,
            classificationProvider: mockClassificationProvider,
            userSession: userSession
        )

        // THEN
        verify(matching: sut)
    }

    func testForNotConnectedNonTeamMember() {
        // GIVEN
        selfUser.teamRole = .none
        mockUser.emailAddress = nil
        mockUser.isTeamMember = false
        mockUser.isConnected = false

        // WHEN
        sut = ProfileViewController(
            user: mockUser,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        sut.viewDidAppear(false)

        // THEN
        verify(matching: sut)
    }
}
