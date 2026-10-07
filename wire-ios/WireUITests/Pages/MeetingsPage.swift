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

import Foundation
import WireNetwork
import XCTest

class MeetingsPage: PageModel {
    override var pageMainElement: XCUIElement {
        createMeetingButton
    }

    var createMeetingButton: XCUIElement {
        app.buttons["scheduleMeetingBarButton"]
    }

    var noUpcomingMeetingsText: XCUIElement {
        app.staticTexts["No upcoming meetings yet"]
    }

    var meetingRows: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "meetingRow."))
    }

    var scheduleMeetingOption: XCUIElement {
        app.buttons["Schedule a Meeting"]
    }

    func schedule() throws -> MeetingFormPage {
        createMeetingButton.tap()
        XCTAssertTrue(scheduleMeetingOption.waitAndTap(), "Schedule a Meeting option did not appear")
        return try MeetingFormPage()
    }

    func row(_ meeting: MeetingResponse, start: Date? = nil) -> XCUIElement {
        app.otherElements[rowIdentifier(meeting, start: start ?? meeting.startTime)]
    }

    @discardableResult
    func showRow(_ meeting: MeetingResponse, start: Date? = nil) throws -> XCUIElement {
        let list = app.descendants(matching: .any)["meetingsList"].firstMatch
        guard list.waitForExistence(timeout: 10) else {
            throw RuntimeError("Meetings list did not appear")
        }

        let target = row(meeting, start: start)
        if target.waitForExistence(timeout: 10), target.isHittable {
            return target
        }

        for _ in 0 ..< 30 {
            if target.exists, target.isHittable {
                return target
            }
            list.swipeUp()
        }

        throw RuntimeError("Meeting '\(meeting.title)' did not appear in the visible list")
    }

    private func rowIdentifier(_ meeting: MeetingResponse, start: Date) -> String {
        "meetingRow.\(meeting.id.domain).\(meeting.id.id.uuidString).\(Int(start.timeIntervalSince1970))"
    }
}
