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

import XCTest
@testable import WireDataModel

/**
 * Tests for calculating the state of external users presence in a team conversation.
 *
 * Expected matrix:
 *
 * +---------------------------------------------------------------------------------+
 * | Conversation Type | Self User  | Other Users          | Expected State For Self |
 * |-------------------|------------|----------------------|-------------------------|
 * | 1:1               | Personal   | Personal             | None                    |
 * | 1:1               | Personal   | Team                 | None                    |
 * | 1:1               | Team       | Team                 | None                    |
 * | 1:1               | Team       | Personal             | None                    |
 * | 1:1               | Team       | Service              | None                    |
 * |-------------------|------------|----------------------|-------------------------|
 * | Group             | Personal   | Personal             | None                    |
 * | Group             | Personal   | Team                 | None                    |
 * | Group             | Team       | Team                 | None                    |
 * | Group             | Team       | Service              | None                    |
 * | Group             | Team       | Personal             | Only Guests             |
 * | Group             | Team       | Team & Service       | Only Services           |
 * | Group             | Personal   | Team & Service       | Only Services           |
 * | Group             | Team       | Personal & Service   | Guests & Services       |
 * +---------------------------------------------------------------------------------+
 */

class ZMConversationExternalParticipantsStateTests: ZMConversationTestsBase {

    enum RelativeUserState {
        case personal
        case memberOfHostingTeam
        case service
    }

    func testOneToOneCases() {
        // Personal Users
        assertMatrixRow(.oneOnOne, selfUser: .personal, otherUsers: [.personal], expectedResult: [])
        assertMatrixRow(.oneOnOne, selfUser: .personal, otherUsers: [.memberOfHostingTeam], expectedResult: [])

        // Team
        assertMatrixRow(.oneOnOne, selfUser: .memberOfHostingTeam, otherUsers: [.memberOfHostingTeam], expectedResult: [])
        assertMatrixRow(.oneOnOne, selfUser: .memberOfHostingTeam, otherUsers: [.personal], expectedResult: [])
        assertMatrixRow(.oneOnOne, selfUser: .memberOfHostingTeam, otherUsers: [.service], expectedResult: [])
    }

    func testGroupCases() {
        // None
        assertMatrixRow(.group, selfUser: .personal, otherUsers: [.personal], expectedResult: [])
        assertMatrixRow(.group, selfUser: .personal, otherUsers: [.memberOfHostingTeam], expectedResult: [])
        assertMatrixRow(.group, selfUser: .memberOfHostingTeam, otherUsers: [.memberOfHostingTeam], expectedResult: [])
        assertMatrixRow(.group, selfUser: .memberOfHostingTeam, otherUsers: [.service], expectedResult: [])

        // Only Guests
        assertMatrixRow(.group, selfUser: .memberOfHostingTeam, otherUsers: [.personal], expectedResult: [.visibleGuests])

        // Only Services
        assertMatrixRow(.group, selfUser: .memberOfHostingTeam, otherUsers: [.memberOfHostingTeam, .service], expectedResult: [.visibleServices])
        assertMatrixRow(.group, selfUser: .personal, otherUsers: [.memberOfHostingTeam, .service], expectedResult: [.visibleServices])

        // Guests and Services
        assertMatrixRow(.group, selfUser: .memberOfHostingTeam, otherUsers: [.personal, .service], expectedResult: [.visibleGuests, .visibleServices])
    }

    // MARK: - Helpers

    func createConversationWithSelfUser() -> ZMConversation {
        let conversation = createConversation(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)
        return conversation
    }

    func assertMatrixRow(_ conversationType: ZMConversationType, selfUser selfUserType: RelativeUserState, otherUsers: [RelativeUserState], expectedResult: ZMConversation.ExternalParticipantsState, file: StaticString = #file, line: UInt = #line) {
        let conversation = createConversationWithSelfUser()
        conversation.conversationType = conversationType

        var hostingTeam: Team?

        switch selfUserType {
        case .memberOfHostingTeam:
            let team = createTeam(in: uiMOC)
            hostingTeam = team
            conversation.team = team
            createMembership(in: uiMOC, user: selfUser, team: team)

        case .personal:
            break

        case .service:
            XCTFail("Self-user cannot be a service", file: file, line: line)
        }

        for otherUserType in otherUsers {
            switch otherUserType {
            case .memberOfHostingTeam:
                if hostingTeam == nil {
                    let team = createTeam(in: uiMOC)
                    hostingTeam = team
                    conversation.team = team
                }

                let otherTeamUser = createUser(in: uiMOC)
                conversation.addParticipantAndUpdateConversationState(user: otherTeamUser, role: nil)
                createMembership(in: uiMOC, user: otherTeamUser, team: hostingTeam!)

            case .personal:
                let otherUser = createUser(in: uiMOC)
                conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)

            case .service:
                let service = createService(in: uiMOC, named: "Bob the Robot")
                conversation.addParticipantAndUpdateConversationState(user: service as! ZMUser, role: nil)
            }
        }

        uiMOC.saveOrRollback()
        XCTAssertEqual(conversation.externalParticipantsState, expectedResult, file: file, line: line)
    }

}
