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

import WireAnalyticsSupport
import XCTest

@testable import WireAnalytics

final class AnalyticsSessionTests: XCTestCase {

    // MARK: - Properties

    private var mockAnalyticsSession: MockAnalyticsSessionProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockAnalyticsSession = MockAnalyticsSessionProtocol()
    }

    // MARK: - tearDown

    override func tearDown() {
        mockAnalyticsSession = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    func testStartSession() {
        // GIVEN
        let expectation = expectation(description: "startSession called")
        mockAnalyticsSession.startSession_MockMethod = {
            expectation.fulfill()
        }

        // WHEN
        mockAnalyticsSession.startSession()

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(mockAnalyticsSession.startSession_Invocations.count, 1)
    }

    func testEndSession() {
        // GIVEN
        let expectation = expectation(description: "endSession called")
        mockAnalyticsSession.endSession_MockMethod = {
            expectation.fulfill()
        }

        // WHEN
        mockAnalyticsSession.endSession()

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(mockAnalyticsSession.endSession_Invocations.count, 1)
    }

    func testTrackEvent() {
        // GIVEN
        let event = AnalyticsEvent.appOpen
        let expectation = expectation(description: "trackEvent called")
        mockAnalyticsSession.trackEvent_MockMethod = { receivedEvent in
            XCTAssertEqual(receivedEvent, event)
            expectation.fulfill()
        }

        // WHEN
        mockAnalyticsSession.trackEvent(event)

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(mockAnalyticsSession.trackEvent_Invocations.count, 1)
        XCTAssertEqual(mockAnalyticsSession.trackEvent_Invocations.first, event)
    }
}
