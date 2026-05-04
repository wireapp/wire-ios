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

import WireDesign
import WireMessagingAssembly
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class StartUIViewControllerSnapshotTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var mockMainCoordinator: AnyMainCoordinator!
    private var sut: StartUIViewController!
    private var userSession: UserSessionMock!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        SelfUser.provider = selfUserProvider
        userSession = UserSessionMock()
        accentColor = .blue
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        SelfUser.provider = nil
        userSession = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    // MARK: - Helper Methods

    func setupSut() {
        sut = StartUIViewController(
            areLegacyBotsAvailable: true,
            isAppsFeatureEnabled: true,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            createGroupConversationUIBuilder: MockCreateGroupConversationViewControllerBuilderProtocol(),
            channelConversationFormFactory: WireConversationChannelCreationFormViewControllerFactory(
                conversationCreationRepository: MockConversationCreationRepositoryProtocol()
            ),
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol()
        )
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault

        // Set the size for the SUT to match iPhone 14 dimensions
        let screenSize = CGSize(width: 390, height: 844)
        sut.view.frame = CGRect(origin: .zero, size: screenSize)
    }

    func setupNavigationController() -> UINavigationController {
        setupSut()
        let navigationController = UINavigationController(rootViewController: sut)
        navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController.overrideUserInterfaceStyle = .dark
        return navigationController
    }

    // MARK: - Snapshot Tests

    func testStartUIViewControllerNoContact() {
        nonTeamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerNoContactWhenSelfIsTeamMember() {
        teamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerNoContactWhenSelfIsPartner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerShowsUsersAppsSelector() {
        teamTest {

            // user is in a team, it's a requirement for apps
            let mockUserType = MockUserType()
            mockUserType.hasTeam = true
            mockUserType.teamRole = .member
            userSession.selfUser = mockUserType

            // selfUser.membership?.setTeamRole(.partner)
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerDoesNotShowNewChannelOptionForPersonalUser() {
        // Given, channels are supported and user is a personal user
        // Note this has been changed for WPB-20233
        userSession.apiVersion = .v8
        userSession.isBackendMLSEnabled = true

        nonTeamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerShowNewChannelOptionForTeamUser() {
        // Given, channels are supported
        userSession.apiVersion = .v8
        userSession.isBackendMLSEnabled = true
        // channels are enabled
        userSession.channelsFeature = Feature.Channels(
            status: .enabled,
            config: .init(
                allowedToCreateChannels: .teamMembers,
                allowedToOpenChannels: .admins
            )
        )
        // user is in a team and is allowed to create a channel
        let mockUserType = MockUserType()
        mockUserType.hasTeam = true
        mockUserType.teamRole = .member
        userSession.selfUser = mockUserType

        let navigationController = setupNavigationController()
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: navigationController.view)
    }

    func testStartUIViewControllerHideNewChannelOptionForTeamUser() {
        // Given, channels are supported
        BackendInfo.apiVersion = .v8
        BackendInfo.isMLSEnabled = true

        // user is in a team
        let mockUserType = MockUserType()
        mockUserType.hasTeam = true
        userSession.selfUser = mockUserType

        // but channels are disabled
        userSession.channelsFeature = Feature.Channels(
            status: .disabled,
            config: .init(
                allowedToCreateChannels: .teamMembers,
                allowedToOpenChannels: .admins
            )
        )

        let navigationController = setupNavigationController()
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: navigationController.view)
    }

}
