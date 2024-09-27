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
import WireTestingPackage
import XCTest
@testable import Wire

final class LegalHoldDetailsViewControllerSnapshotTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        userSession = UserSessionMock()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = SelfUser.provider?.providedSelfUser as? MockUserType
        selfUser.handle = nil
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        SelfUser.provider = nil
        userSession = nil
        super.tearDown()
    }

    // MARK: - Helper method

    func setUpLegalHoldDetailsViewController(conversation: MockGroupDetailsConversation) -> () -> UIViewController {
        {
            self.sut = LegalHoldDetailsViewController(
                conversation: conversation,
                userSession: self.userSession,
                mainCoordinator: .mock
            )
            return self.sut.wrapInNavigationController()
        }
    }

    // MARK: - Snapshot Tests

    func testSelfUserUnderLegalHold() {
        // GIVEN
        let conversation = MockGroupDetailsConversation()
        selfUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [selfUser]

        // WHEN
        let sut = setUpLegalHoldDetailsViewController(conversation: conversation)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut(),
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut(),
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }

    func testOtherUserUnderLegalHold() {
        // GIVEN
        let conversation = MockGroupDetailsConversation()
        let otherUser = SwiftMockLoader.mockUsers().first!
        otherUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [otherUser]

        let createSut: () -> UIViewController = {
            self.sut = LegalHoldDetailsViewController(
                conversation: conversation,
                userSession: self.userSession,
                mainCoordinator: .mock
            )
            return self.sut.wrapInNavigationController()
        }

        let sut = createSut()

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: LegalHoldDetailsViewController!
    private var selfUser: MockUserType!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!
}
