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

    private var analyticsService: MockAnalyticsServiceProtocol!
    private var sut: AnalyticsManager<MockCountlyAbstraction>!

    // MARK: - setUp

    override func setUp() {
        analyticsService = .init()
        analyticsService.startAppKeyHost_MockMethod = { _, _ in }
        analyticsService.beginSession_MockMethod = {}
        analyticsService.endSession_MockMethod = {}
        analyticsService.changeDeviceIDMergeData_MockMethod = { _, _ in }
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
    }

    func testInitialization() {
        guard analyticsService.startAppKeyHost_Invocations.count == 1 else {
            XCTFail("Expected 1 invocation of startAppKeyHost, but got \(analyticsService.startAppKeyHost_Invocations.count)")
            return
        }
        XCTAssertEqual(analyticsService.startAppKeyHost_Invocations[0].appKey, "testAppKey")
        XCTAssertEqual(analyticsService.startAppKeyHost_Invocations[0].host, URL(string: "https://test.com")!)
    }

    func testSwitchUser() {
        // GIVEN
        let userProfile = AnalyticsUserProfile(
            analyticsIdentifier: "testUser123",
            teamInfo: .init(id: "team1", role: "admin", size: 10)
        )

        // WHEN
        _ = sut.switchUser(userProfile)

        // THEN
        XCTAssertEqual(analyticsService.endSession_Invocations.count, 1)
        guard analyticsService.changeDeviceIDMergeData_Invocations.count == 1 else {
            XCTFail("Expected 1 invocation of changeDeviceIDMergeData, but got \(analyticsService.changeDeviceIDMergeData_Invocations.count)")
            return
        }
        XCTAssertEqual(analyticsService.changeDeviceIDMergeData_Invocations[0].id, "testUser123")
        XCTAssertFalse(analyticsService.changeDeviceIDMergeData_Invocations[0].mergeData)

        guard analyticsService.setUserValueForKey_Invocations.count == 3 else {
            XCTFail("Expected 3 invocations of setUserValueForKey, but got \(analyticsService.setUserValueForKey_Invocations.count)")
            return
        }
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
        // GIVEN
        let userProfile = AnalyticsUserProfile(
            analyticsIdentifier: "testUser456",
            teamInfo: nil
        )

        // WHEN
        _ = sut.switchUser(userProfile)

        // THEN
        XCTAssertEqual(analyticsService.endSession_Invocations.count, 1)
        guard analyticsService.changeDeviceIDMergeData_Invocations.count == 1 else {
            XCTFail("Expected 1 invocation of changeDeviceIDMergeData, but got \(analyticsService.changeDeviceIDMergeData_Invocations.count)")
            return
        }
        XCTAssertEqual(analyticsService.changeDeviceIDMergeData_Invocations[0].id, "testUser456")
        XCTAssertFalse(analyticsService.changeDeviceIDMergeData_Invocations[0].mergeData)

        guard analyticsService.setUserValueForKey_Invocations.count == 3 else {
            XCTFail("Expected 3 invocations of setUserValueForKey, but got \(analyticsService.setUserValueForKey_Invocations.count)")
            return
        }
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[0].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[0].key, "team_team_id")
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[1].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[1].key, "team_user_type")
        XCTAssertNil(analyticsService.setUserValueForKey_Invocations[2].value)
        XCTAssertEqual(analyticsService.setUserValueForKey_Invocations[2].key, "team_team_size")

        XCTAssertEqual(analyticsService.beginSession_Invocations.count, 1)
    }

}
