//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSyncEngineSupport
import XCTest

@testable import Wire

final class ProfileViewTests: BaseSnapshotTestCase {

    var userSession: UserSessionMock!

    var isSelfUserVerifiedUseCase: MockIsSelfUserVerifiedUseCaseProtocol!
    var hasSelfUserValidE2EICertificatesForAllClientsUseCase: MockHasSelfUserValidE2EICertificatesForAllClientsUseCaseProtocol!

    override func setUp() {
        super.setUp()

        userSession = UserSessionMock()
        isSelfUserVerifiedUseCase = .init()
        isSelfUserVerifiedUseCase.invoke_MockValue = false
        hasSelfUserValidE2EICertificatesForAllClientsUseCase = .init()
        hasSelfUserValidE2EICertificatesForAllClientsUseCase.invoke_MockValue = false
    }

    override func tearDown() {
        isSelfUserVerifiedUseCase = nil
        hasSelfUserValidE2EICertificatesForAllClientsUseCase = nil
        userSession = nil

        super.tearDown()
    }

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

    func test_HideName() {
        verifyProfile(options: [.hideUsername])
    }

    func test_HideTeamName() {
        verifyProfile(options: [.hideTeamName])
    }

    func test_HideHandle() {
        verifyProfile(options: [.hideHandle])
    }

    func test_HideNameAndHandle() {
        verifyProfile(options: [.hideUsername, .hideHandle])
    }

    func test_HideAvailability() {
        verifyProfile(options: [.hideAvailability])
    }

    func test_notConnectedUser() {
        // GIVEN
        let selfUser = MockUserType.createSelfUser(name: "selfUser", inTeam: UUID())
        let testUser = MockUserType.createUser(name: "Test")
        testUser.isConnected = false

        // when
        let sut = ProfileHeaderViewController(
            user: testUser,
            viewer: selfUser,
            conversation: nil,
            options: [],
            userSession: userSession,
            isSelfUserVerifiedUseCase: isSelfUserVerifiedUseCase,
            hasSelfUserValidE2EICertificatesForAllClientsUseCase: hasSelfUserValidE2EICertificatesForAllClientsUseCase
        )

        sut.view.frame.size = sut.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut.view)
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

        verify(matching: sut.view, file: file, testName: testName, line: line)
    }

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
            isSelfUserVerifiedUseCase: isSelfUserVerifiedUseCase,
            hasSelfUserValidE2EICertificatesForAllClientsUseCase: hasSelfUserValidE2EICertificatesForAllClientsUseCase
        )
        sut.view.frame.size = sut.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault
        sut.overrideUserInterfaceStyle = .dark
        return sut
    }
}
