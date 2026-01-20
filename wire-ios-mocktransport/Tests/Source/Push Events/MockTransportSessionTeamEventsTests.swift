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

import XCTest

@testable import WireMockTransport

final class MockTransportSessionTeamEventsTests: MockTransportSessionTests {

    func check(
        event: TestPushChannelEvent?,
        hasType type: ZMUpdateEventType,
        team: MockTeam,
        data: [String: String] = [:],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        check(event: event, hasType: type, teamIdentifier: team.identifier, data: data, file: file, line: line)
    }

    func check(
        event: TestPushChannelEvent?,
        hasType type: ZMUpdateEventType,
        teamIdentifier: String,
        data: [String: String?] = [:],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let event else { XCTFail("Should have event", file: file, line: line); return }

        XCTAssertEqual(
            event.type,
            type,
            "Wrong type \(String(describing: ZMUpdateEvent.eventTypeString(for: type)))",
            file: file,
            line: line
        )

        guard let payload = event.payload as? [String: Any] else { XCTFail(
            "Event should have payload",
            file: file,
            line: line
        ); return }

        XCTAssertEqual(payload["team"] as? String, teamIdentifier, "Wrong team identifier", file: file, line: line)
        guard let date = (payload as NSDictionary).optionalDate(forKey: "time")
        else { XCTFail("Event should have time", file: file, line: line); return }

        // workaroud: the date decoded from a string can have a rounded time in the milliseconds and then be "in the future",
        // so we add one second here for the comparison to avoid flakiness.
        XCTAssertLessThan(
            date,
            Date(timeIntervalSinceNow: 1),
            "Event date should be in the past",
            file: file,
            line: line
        )

        guard !data.isEmpty else {
            return
        }
        guard let receivedData = payload["data"] as? [String: String?]
        else { XCTFail("Event payload should have data", file: file, line: line); return }

        for (key, value) in data {
            guard let dataValue = receivedData[key] else {
                XCTFail("Event payload data does not contain key: \"\(key)\"", file: file, line: line)
                continue
            }
            XCTAssertEqual(
                dataValue,
                value,
                "Event payload data for \"\(key)\" does not match, expected \"\(String(describing: value))\", got \"\(String(describing: dataValue))\"",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Team events

    // MARK: - Members events

    func testThatItDoesNotSendEventsFromATeamThatYouAreNotAMemberOf() {
        // Given
        createAndOpenPushChannel()

        // When
        sut.performRemoteChanges { session in
            let user1 = session.insertUser(withName: "one")
            let team = session.insertTeam(withName: "some", isBound: true, users: [user1])

            let user2 = session.insertUser(withName: "some user")
            _ = session.insertTeamConversation(to: team, with: [user1, user2], creator: user1)
        }

        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 0)
    }

}
