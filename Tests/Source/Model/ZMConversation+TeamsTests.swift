//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import WireTesting
@testable import WireDataModel


class ZMConversationTests_Teams: BaseTeamTests {

    var team: Team!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
    }

    override func tearDown() {
        team = nil
        conversation = nil
        super.tearDown()
    }

    func testThatItDoesNotReportIsGuestForANonTeamConversation() {
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItDoesNotReportIsGuestForATeamConversation() {
        // given
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItReportsIsGuestWhenAConversationDoesNotHaveATeam() {
        // given
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssert(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItSetsTheConversationTeamRemoteIdentifierWhenUpdatingWithTransportData() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = .create()
        let teamId = UUID.create()
        let payload = payloadForConversationmetaData(conversation, activeUsers: [user], teamId: teamId)

        // when
        performPretendingUiMocIsSyncMoc {
            self.conversation.update(withTransportData: payload)
        }

        // then
        guard let team = Team.fetch(withRemoteIdentifier: teamId, in: uiMOC) else { return XCTFail("No team") }
        XCTAssertNotNil(conversation.teamRemoteIdentifier)
        XCTAssertEqual(conversation.teamRemoteIdentifier, teamId)
        XCTAssertTrue(team.needsToBeUpdatedFromBackend)

        // when we receive a 403 and delete the team
        // We need to nil the relationship before deleting the team (otherwise the delete will cascade and delete the conversation as well)
        conversation.team = nil
        uiMOC.delete(team)
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertNil(conversation.team)
        XCTAssertEqual(conversation.teamRemoteIdentifier, teamId)
        XCTAssert(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    // MARK: - Helper

    private func payloadForConversationmetaData(_ conversation: ZMConversation, activeUsers: [ZMUser], teamId: UUID?) -> [String: Any] {
        var payload: [String: Any] = [
            "last_event_time": "2014-04-30T16:30:16.625Z",
            "name": NSNull(),
            "type": NSNumber(value: ZMBackendConversationType.convTypeGroup.rawValue),
            "id": conversation.remoteIdentifier!.transportString(),
            "creator": UUID.create().transportString(),
            "members": [
                "others": activeUsers.map { ["status": NSNumber(value: 0), "id": $0.remoteIdentifier!.transportString()] },
                "self": [
                    "status": NSNumber(value: 0),
                    "muted_time": NSNull(),
                    "status_ref": "0.0",
                    "last_read": "5.800112314308490f",
                    "status_time": "2014-03-14T16:47:37.573Z",
                    "id": "3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                    "otr_archived": NSNumber(value: 0),
                    "otr_archived_ref": NSNull(),
                    "otr_muted": NSNumber(value: 0),
                    "otr_muted_ref": NSNull()
                ]
            ]
        ]

        if let teamId = teamId {
            payload["team"] = teamId
        } else {
            payload["team"] = NSNull()
        }

        return payload
    }

}
