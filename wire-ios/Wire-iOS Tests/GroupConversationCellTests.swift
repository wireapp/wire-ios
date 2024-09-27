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

import WireTestingPackage
import XCTest
@testable import Wire

final class GroupConversationCellTests: XCTestCase {
    private var sut: GroupConversationCell!
    private var otherUser: MockUserType!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        otherUser = MockUserType.createDefaultOtherUser()
        sut = GroupConversationCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        otherUser = nil

        super.tearDown()
    }

    private func createOneOnOneConversation() -> MockStableRandomParticipantsConversation {
        otherUser = MockUserType.createDefaultOtherUser()

        let otherUserConversation = MockStableRandomParticipantsConversation
            .createOneOnOneConversation(otherUser: otherUser)

        return otherUserConversation
    }

    private func createGroupConversation() -> MockStableRandomParticipantsConversation {
        let groupConversation = MockStableRandomParticipantsConversation()

        var mockUsers = [MockUserType]()
        for username in MockUserType.usernames.prefix(upTo: 3) {
            mockUsers.append(MockUserType.createUser(name: username))
        }

        groupConversation.stableRandomParticipants = [mockUsers[0], otherUser, mockUsers[1], mockUsers[2]]

        return groupConversation
    }

    private func verify(
        conversation: GroupConversationCellConversation,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        sut.configure(conversation: conversation)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: file,
                testName: testName,
                line: line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: file,
                testName: testName,
                line: line
            )
    }

    func testOneToOneConversation() {
        // GIVEN & WHEN
        let otherUserConversation = createOneOnOneConversation()

        // THEN
        verify(conversation: otherUserConversation)
    }

    func testGroupConversation() {
        // GIVEN
        let groupConversation = createGroupConversation()

        // WHEN
        groupConversation.displayName = "Anna, Bruno, Claire, Dean"

        // THEN
        verify(conversation: groupConversation)
    }

    func testGroupConversationWithVeryLongName() {
        // GIVEN
        let groupConversation = createGroupConversation()

        // WHEN
        groupConversation.displayName = "Loooooooooooooooooooooooooong name"

        // THEN
        verify(conversation: groupConversation)
    }
}
