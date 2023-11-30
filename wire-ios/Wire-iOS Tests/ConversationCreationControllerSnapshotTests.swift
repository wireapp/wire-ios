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

final class ConversationCreationControllerSnapshotTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: ConversationCreationController!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForEditingTextField() {
        createSut(isTeamMember: false)

        verify(matching: sut)
    }

    func testTeamGroupOptionsCollapsed() {
        createSut(isTeamMember: true)

        verify(matching: sut)
    }

    func testTeamGroupOptionsCollapsed_dark() {
        createSut(isTeamMember: true, userInterfaceStyle: .dark)

        verify(matching: sut)
    }

    func testTeamGroupOptionsExpanded() {
        createSut(isTeamMember: true)
        sut.expandOptions()

        verify(matching: sut)
    }

    // MARK: - Helper Method

    private func createSut(
        isTeamMember: Bool,
        userInterfaceStyle: UIUserInterfaceStyle = .light
    ) {
        let mockSelfUser = MockUserType.createSelfUser(name: "Alice", inTeam: isTeamMember ? UUID() : nil)
        let mockUserSession = UserSessionMock(mockUser: mockSelfUser)
        sut = ConversationCreationController(preSelectedParticipants: nil, userSession: mockUserSession)
        sut.overrideUserInterfaceStyle = userInterfaceStyle
    }
}
