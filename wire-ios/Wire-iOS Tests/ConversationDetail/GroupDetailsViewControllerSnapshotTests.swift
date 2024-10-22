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

import WireMainNavigationUI
import WireTestingPackage
import XCTest

@testable import Wire

final class GroupDetailsViewControllerSnapshotTests: XCTestCase {

    private var mockMainCoordinator: AnyMainCoordinator<Wire.MainCoordinatorDependencies>!
    private var sut: GroupDetailsViewController!
    private var mockConversation: MockGroupDetailsConversation!
    private var mockSelfUser: MockUserType!
    private var otherUser: MockUserType!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {
        snapshotHelper = SnapshotHelper()
        mockConversation = MockGroupDetailsConversation()
        mockConversation.displayName = "iOS Team"
        mockConversation.securityLevel = .notSecure

        mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        mockSelfUser.remoteIdentifier = .init()
        mockSelfUser.handle = nil

        SelfUser.provider = SelfProvider(providedSelfUser: mockSelfUser)

        otherUser = MockUserType.createUser(name: "Bruno")
        otherUser.remoteIdentifier = .init()
        otherUser.isConnected = true
        otherUser.handle = "bruno"
        otherUser.zmAccentColor = .amber

        userSession = UserSessionMock(mockUser: mockSelfUser)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockConversation = nil
        mockSelfUser = nil
        otherUser = nil
        userSession = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    private func setSelfUserInTeam() {
        mockSelfUser.hasTeam = true
        mockSelfUser.teamIdentifier = UUID()
        mockSelfUser.isGroupAdminInConversation = true
        mockSelfUser.canModifyNotificationSettingsInConversation = true
    }

    private func createGroupConversation() {
        mockConversation.sortedOtherParticipants = [otherUser, mockSelfUser]
    }

    func testForOptionsForTeamUserInNonTeamConversation() {
        // GIVEN & WHEN

        mockSelfUser.canModifyTitleInConversation = true
        mockSelfUser.canAddUserToConversation = true
        mockSelfUser.canModifyEphemeralSettingsInConversation = true

        // self user has team
        setSelfUserInTeam()

        otherUser.isGuestInConversation = true
        otherUser.teamRole = .none

        createGroupConversation()

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForOptionsForTeamUserInNonTeamConversation_Partner() {
        // GIVEN & WHEN
        setSelfUserInTeam()
        mockSelfUser.canAddUserToConversation = false

        mockSelfUser.teamRole = .partner

        createGroupConversation()

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForOptionsForTeamUserInTeamConversation() {
        // GIVEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .member

        mockSelfUser.canModifyTitleInConversation = true
        mockSelfUser.canModifyEphemeralSettingsInConversation = true
        mockSelfUser.canModifyNotificationSettingsInConversation = true
        mockSelfUser.canModifyReadReceiptSettingsInConversation = true
        mockSelfUser.canModifyAccessControlSettings = true

        createGroupConversation()
        mockConversation.teamRemoteIdentifier = mockSelfUser.teamIdentifier
        mockConversation.allowGuests = true
        mockConversation.allowServices = true

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForOptionsForTeamUserInTeamConversation_Partner() {
        // GIVEN & WHEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .partner
        mockSelfUser.canAddUserToConversation = false

        createGroupConversation()
        mockConversation.teamRemoteIdentifier = mockSelfUser.teamIdentifier

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForOptionsForNonTeamUser() {
        // GIVEN
        mockSelfUser.canModifyTitleInConversation = true
        mockSelfUser.isGroupAdminInConversation = true
        mockSelfUser.canModifyEphemeralSettingsInConversation = true

        mockConversation.sortedOtherParticipants = [otherUser, mockSelfUser]

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testForOptionsForTeamUserInTeamConversation_Admins() throws {
        // GIVEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .admin
        mockSelfUser.canModifyEphemeralSettingsInConversation = true
        mockSelfUser.canModifyTitleInConversation = true

        mockConversation.sortedOtherParticipants = [mockSelfUser]
        mockConversation.displayName = "Empty group conversation"

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        snapshotHelper.verify(matching: sut)
    }

    func testForMlsConversation_withVerifiedStatus() throws {
        // GIVEN & WHEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .admin
        mockConversation.sortedOtherParticipants = [mockSelfUser]

        mockConversation.messageProtocol = .mls
        mockConversation.mlsVerificationStatus = .verified

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    func testForMlsConversation_withNotVerifiedStatus() throws {
        // GIVEN & WHEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .admin
        mockConversation.sortedOtherParticipants = [mockSelfUser]

        mockConversation.messageProtocol = .mls
        mockConversation.mlsVerificationStatus = .notVerified

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    func testForProteusConversation_withVerifiedStatus() throws {
        // GIVEN & WHEN
        setSelfUserInTeam()
        mockSelfUser.teamRole = .admin
        mockConversation.sortedOtherParticipants = [mockSelfUser]

        mockConversation.messageProtocol = .proteus
        mockConversation.securityLevel = .secure

        sut = GroupDetailsViewController(
            conversation: mockConversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )

        // THEN
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }
}
