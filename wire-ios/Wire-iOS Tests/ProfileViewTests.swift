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

import WireDataModelSupport
import WireDesign
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ProfileViewTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper_!
    private var userSession: UserSessionMock!
    private var isUserE2EICertifiedUseCase: MockIsUserE2EICertifiedUseCaseProtocol!
    private var isSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        userSession = UserSessionMock()
        isUserE2EICertifiedUseCase = .init()
        isUserE2EICertifiedUseCase.invokeConversationUser_MockValue = false
        isSelfUserE2EICertifiedUseCase = .init()
        isSelfUserE2EICertifiedUseCase.invoke_MockValue = false
    }

    override func tearDown() {
        snapshotHelper = nil
        isUserE2EICertifiedUseCase = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func test_DefaultOptions() {
        verifyProfile(options: [])
    }

    func testDefaultOptions_NoAvailability() {
        verifyProfile(options: [], availability: .none)
    }

    func testDefaultOptions_NoAvailability_Edit() {
        verifyProfile(options: [.allowEditingAvailability], availability: .none)
    }

    func test_DefaultOptions_AllowEditing() {
        verifyProfile(options: [.allowEditingAvailability])
    }

    func test_HideTeamName() {
        verifyProfile(options: [.hideTeamName])
    }

    func test_HideAvailability() {
        verifyProfile(options: [.hideAvailability])
    }

    func test_notConnectedUser_DarkMode() {
        // GIVEN
        let selfUser = MockUserType.createSelfUser(name: "selfUser", inTeam: UUID())
        let testUser = MockUserType.createUser(name: "Test")
        testUser.isConnected = false

        // WHEN
        let sut = ProfileHeaderViewController(
            user: testUser,
            viewer: selfUser,
            conversation: nil,
            options: [],
            userSession: userSession,
            isUserE2EICertifiedUseCase: isUserE2EICertifiedUseCase,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase
        )

        sut.view.frame.size = sut.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.view)
    }

    func verifyProfile(
        options: ProfileHeaderViewController.Options,
        availability: Availability = .available,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let selfUser = MockUserType.createSelfUser(name: "selfUser", inTeam: UUID())
        selfUser.teamName = "Stunning"
        selfUser.handle = "browncow"
        selfUser.availability = availability

        let sut = setupProfileHeaderViewController(user: selfUser, viewer: selfUser, options: options)

        snapshotHelper.verify(matching: sut.view, file: file, testName: testName, line: line)
    }

    // MARK: - Helper Method

    func setupProfileHeaderViewController(
        user: UserType,
        viewer: UserType,
        options: ProfileHeaderViewController.Options = []
    ) -> ProfileHeaderViewController {
        let sut = ProfileHeaderViewController(
            user: user,
            viewer: viewer,
            conversation: nil,
            options: options,
            userSession: userSession,
            isUserE2EICertifiedUseCase: isUserE2EICertifiedUseCase,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase
        )
        sut.view.frame.size = sut.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault
        sut.overrideUserInterfaceStyle = .dark
        return sut
    }
}
