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

final class ConversationCreationControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    var sut: ConversationCreationController!

    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .purple
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForEditingTextField() {
        createSut(isTeamMember: false)

        snapshotHelper.verify(matching: sut)
    }

    func testTeamGroupOptionsCollapsed() {
        createSut(isTeamMember: true)

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

    func testTeamGroupOptionsExpanded() {
        createSut(isTeamMember: true)
        sut.expandOptions()

        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Helper Method

    private func createSut(isTeamMember: Bool) {
        let mockSelfUser = MockUserType.createSelfUser(name: "Alice", inTeam: isTeamMember ? UUID() : nil)
        let mockUserSession = UserSessionMock(mockUser: mockSelfUser)
        sut = ConversationCreationController(preSelectedParticipants: nil, userSession: mockUserSession)
    }
}
