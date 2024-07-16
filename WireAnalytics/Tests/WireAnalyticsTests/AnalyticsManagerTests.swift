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

@testable import WireAnalytics
@testable import WireAnalyticsSupport

class AnalyticsManagerTests: XCTestCase {

    // MARK: - Properties

    private var analyticsService: MockAnalyticsService!
    private var sut: AnalyticsManager!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        analyticsService = MockAnalyticsService()

        analyticsService.startAppKeyHost_MockMethod = { _, _ in }
        analyticsService.beginSession_MockMethod = {}
        analyticsService.endSession_MockMethod = {}
        analyticsService.changeDeviceID_MockMethod = { _ in }
        analyticsService.setUserValueForKey_MockMethod = { _, _ in }

        sut = AnalyticsManager(
            appKey: "testAppKey",
            host: URL(string: "https://test.com")!,
            analyticsService: analyticsService
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        analyticsService = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Unit Tests

    func testInitialization() {
        XCTAssertEqual(analyticsService.startAppKeyHost_Invocations.count, 1)
        XCTAssertEqual(analyticsService.startAppKeyHost_Invocations[0].appKey, "testAppKey")
        XCTAssertEqual(analyticsService.startAppKeyHost_Invocations[0].host, URL(string: "https://test.com")!)
    }

    func testSwitchUser() {
        let userProfile = AnalyticsUserProfile(
            analyticsIdentifier: "testUser123",
            teamInfo: .init(id: "team1", role: "admin", size: 10)
        )

        _ = sut.switchUser(userProfile)

        XCTAssertEqual(analyticsService.endSession_Invocations.count, 1)
        XCTAssertEqual(analyticsService.changeDeviceID_Invocations.count, 1)
        XCTAssertEqual(analyticsService.changeDeviceID_Invocations[0], "testUser123")

        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations.count, 3)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[0].value, "team1")
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[0].key, "team_team_id")
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[1].value, "admin")
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[1].key, "team_user_type")

        // Check for the rounded value
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[2].value, "3")
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[2].key, "team_team_size")

        XCTAssertEqual(analyticsService.beginSession_Invocations.count, 1)
    }

    func testSwitchUserWithNilTeamInfo() {
        let userProfile = AnalyticsUserProfile(
            analyticsIdentifier: "testUser456",
            teamInfo: nil
        )

        _ = sut.switchUser(userProfile)

        XCTAssertEqual(analyticsService.endSession_Invocations.count, 1)
        XCTAssertEqual(analyticsService.changeDeviceID_Invocations.count, 1)
        XCTAssertEqual(analyticsService.changeDeviceID_Invocations[0], "testUser456")

        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations.count, 3)
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[0].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[0].key, "team_team_id")
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[1].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[1].key, "team_user_type")
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[2].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[2].key, "team_team_size")

        XCTAssertEqual(analyticsService.beginSession_Invocations.count, 1)
    }

}
