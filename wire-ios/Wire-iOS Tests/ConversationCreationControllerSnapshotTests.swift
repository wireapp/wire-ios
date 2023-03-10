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

final class ConversationCreationControllerSnapshotTests: ZMSnapshotTestCase {

    var sut: ConversationCreationController!

    override func setUp() {
        super.setUp()
        accentColor = .violet
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func createSut(isTeamMember: Bool) {
        let mockSelfUser = MockUserType.createSelfUser(name: "Alice", inTeam:
            isTeamMember ? UUID() : nil)
        sut = ConversationCreationController(preSelectedParticipants: nil, selfUser: mockSelfUser)
    }

    func testForEditingTextField() {
        createSut(isTeamMember: false)

        verify(matching: sut)
    }

    func testTeamGroupOptionsCollapsed() {
        createSut(isTeamMember: true)

        verify(matching: sut)
    }

    func testTeamGroupOptionsCollapsed_dark() {
        createSut(isTeamMember: true)

        sut.overrideUserInterfaceStyle = .dark

        verify(matching: sut)
    }

    func testTeamGroupOptionsExpanded() {
        createSut(isTeamMember: true)

        sut.optionsExpanded = true

        verify(matching: sut)
    }
}
