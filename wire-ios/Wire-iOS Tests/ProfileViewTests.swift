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

import WireDataModelSupport
import WireDesign
import WireLocators
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ProfileViewTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var userSession: UserSessionMock!
    private var isUserE2EICertifiedUseCase: MockIsUserE2EICertifiedUseCaseProtocol!
    private var isSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
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

    @MainActor
    func testSelfProfileNameRemainsAccessible() throws {
        let selfUser = MockUserType.createSelfUser(name: "Profile Name", inTeam: UUID())
        let sut = setupProfileHeaderViewController(user: selfUser, viewer: selfUser)
        let name = try XCTUnwrap(profileSubview(in: sut.view, identifier: Locators.UserProfilePage.name.rawValue))

        XCTAssertTrue(name.isAccessibilityElement)
        XCTAssertEqual(name.accessibilityLabel, L10n.Accessibility.AccountPage.Name.description)
        XCTAssertEqual(name.accessibilityValue, "Profile Name")
        XCTAssertTrue(name.accessibilityTraits.contains(.header))
    }

    @MainActor
    func testEligibleSelfProfileQRCodeButtonRemainsAccessible() async throws {
        let selfUser = MockUserType.createSelfUser(name: "Profile Name", inTeam: UUID())
        XCTAssertNil(userSession.clientSessionComponent)
        let sut = setupProfileHeaderViewController(user: selfUser, viewer: selfUser)
        let button = try XCTUnwrap(profileSubview(
            in: sut.view,
            identifier: Locators.UserProfilePage.qrCodeButton.rawValue
        ) as? UIButton)
        // The main-actor eligibility task cannot run until this test first suspends.
        // Hide the initially visible button so only that task can satisfy the expectation.
        button.isHidden = true
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !button.isHidden }, object: nil)
        await fulfillment(of: [visible], timeout: 2)

        XCTAssertTrue(button.isAccessibilityElement)
        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
        XCTAssertEqual(button.accessibilityLabel, L10n.Accessibility.Profile.ShareProfileButton.description)
        XCTAssertNotNil(button.superview)
    }

    func testProfileLinkDescriptorRefreshesAccessibilityValue() throws {
        let previousProvider = SelfUser.provider
        defer { SelfUser.provider = previousProvider }
        let selfUser = MockUserType.createSelfUser(name: "Profile Name")
        selfUser.remoteIdentifier = UUID()
        selfUser.domain = "wire.example"
        SelfUser.provider = SelfProvider(providedSelfUser: selfUser)
        let expectedLink = try XCTUnwrap(URL.selfUserProfileLink?.absoluteString.removingPercentEncoding)
        let cell = SettingsLinkTableCell()
        cell.linkText = NSAttributedString(string: "Previous link")
        cell.setupAccessibility()
        XCTAssertEqual(cell.accessibilityValue, "Previous link")

        SettingsProfileLinkCellDescriptor().featureCell(cell)

        XCTAssertTrue(cell.isAccessibilityElement)
        XCTAssertEqual(cell.accessibilityValue, expectedLink)
    }

    private func profileSubview(in view: UIView, identifier: String) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        return view.subviews.lazy.compactMap { [self] in profileSubview(in: $0, identifier: identifier) }.first
    }

    func verifyProfile(
        options: ProfileHeaderViewController.Options,
        availability: Availability = .available,
        file: StaticString = #filePath,
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
