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

import XCTest
@testable import WireDataModel

class ZMConversationPerformanceTests: ZMConversationTestsBase {
    // MARK: Internal

    /// There are no true 1:1 conversations in teams, so we check to see if it
    /// should be considered a 1:1 depending on certain properties. This was
    /// previously expensive because the conversation participants were iterated
    /// over several times. The implementation has been optimized to avoid iterating
    /// over the conversation participants entirely.

    func testPerformanceWhenCalculatingConversationType() {
        // Given
        let conversation = createLargeTeamGroupConversation()

        // The typical worst case scenario is where we need to check the local participants
        // since this is where the bottleneck is most likely to occur. To ensure that
        // we check the local participants, we assert that all other criteria is satisfied,
        // otherwise some boolean expressions may return early (due to short circuiting).

        XCTAssertEqual(conversation.conversationType, .group)
        XCTAssertNotNil(conversation.teamRemoteIdentifier)
        XCTAssertTrue(conversation.userDefinedName?.isEmpty ?? true)

        measure {
            // When
            _ = conversation.conversationType
        }
    }

    // MARK: Private

    private func createLargeTeamGroupConversation() -> ZMConversation {
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        let users: [ZMUser] = (0 ..< 299).map { _ in
            let otherUser = ZMUser.insertNewObject(in: uiMOC)
            let otherMember = Member.insertNewObject(in: uiMOC)
            otherMember.team = team
            otherMember.user = otherUser
            return otherUser
        }

        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users, team: team)!
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        return conversation
    }
}
