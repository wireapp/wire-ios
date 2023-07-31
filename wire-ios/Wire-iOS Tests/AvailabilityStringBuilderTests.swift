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

import XCTest
@testable import Wire

final class AvailabilityStringBuilderTests: XCTestCase {

    // MARK: - Properties

    var otherUser: ZMUser!
    var selfUser: ZMUser!
    var team1: Team!
    var team2: Team!
    var fixture: CoreDataFixture!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        fixture = CoreDataFixture()
        selfUser = ZMUser.selfUser(in: fixture.uiMOC)
        otherUser = ZMUser.insertNewObject(in: fixture.uiMOC)
        otherUser.availability = .available
        team1 = Team.insertNewObject(in: fixture.uiMOC)
        team1.remoteIdentifier = UUID()
        team2 = Team.insertNewObject(in: fixture.uiMOC)
        team2.remoteIdentifier = UUID()
    }

    // MARK: - tearDown

    override func tearDown() {
        selfUser = nil
        otherUser = nil
        team1 = nil
        team2 = nil
        fixture = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testThatTheresAvailabilityInformationOtherUserIsNotTeammate() {
        // GIVEN
        let member = Member.insertNewObject(in: fixture.uiMOC)
        member.user = otherUser
        member.team = team2
        otherUser.updateAvailability(.available)

        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1

        // WHEN
        let listString = AvailabilityStringBuilder.string(for: otherUser, with: .list, color: UIColor.black)
        let participantsString = AvailabilityStringBuilder.string(for: otherUser, with: .participants, color: UIColor.black)

        // THEN
        XCTAssertFalse(listString!.allAttachments.isEmpty)
        XCTAssertFalse(participantsString!.allAttachments.isEmpty)
    }

    func testThatTheresAvailabilityInformationIfOtherUserIsTeamMember() {
        // GIVEN
        let member = Member.insertNewObject(in: fixture.uiMOC)
        member.user = otherUser
        member.team = team1
        otherUser.updateAvailability(.available)

        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1

        // WHEN
        let listString = AvailabilityStringBuilder.string(for: otherUser, with: .list, color: UIColor.black)
        let participantsString = AvailabilityStringBuilder.string(for: otherUser, with: .participants, color: UIColor.black)

        // THEN
        XCTAssertFalse(listString!.allAttachments.isEmpty)
        XCTAssertFalse(participantsString!.allAttachments.isEmpty)
    }

    func testThatTheresAvailabilityInformationIfSelfUser() {
        // GIVEN
        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1
        selfUser.updateAvailability(.available)

        // WHEN
        let listString = AvailabilityStringBuilder.string(for: selfUser, with: .list, color: UIColor.black)
        let participantsString = AvailabilityStringBuilder.string(for: selfUser, with: .participants, color: UIColor.black)

        // THEN
        XCTAssertFalse(listString!.allAttachments.isEmpty)
        XCTAssertFalse(participantsString!.allAttachments.isEmpty)
    }
}
