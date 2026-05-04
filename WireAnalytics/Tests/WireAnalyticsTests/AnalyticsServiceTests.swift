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

import WireFoundation
import XCTest

@testable import WireAnalytics
@testable import WireAnalyticsSupport

final class AnalyticsServiceTests: XCTestCase {

    private var sut: AnalyticsService!
    private var countlyMock: CountlyProtocolMock!

    @MainActor
    override func setUp() async throws {
        countlyMock = .init()
        sut = AnalyticsService(
            config: Scaffolding.config,
            baseSegmentation: Scaffolding.baseSegmentation,
            countlyProvider: { self.countlyMock }
        )
    }

    override func tearDown() {
        countlyMock = nil
        sut = nil
    }

    func resetMockInvocations() {
        countlyMock.startAppKeyStringHostURLVoidCallsCount = 0
        countlyMock.startAppKeyStringHostURLVoidReceivedInvocations = []
        countlyMock.endSessionVoidCallsCount = 0
        countlyMock.beginSessionVoidCallsCount = 0
        countlyMock.changeDeviceIDIdStringMergeDataBoolVoidCallsCount = 0
        countlyMock.changeDeviceIDIdStringMergeDataBoolVoidReceivedInvocations = []
        countlyMock.setUserValueValueStringForKeyKeyStringVoidCallsCount = 0
        countlyMock.setUserValueValueStringForKeyKeyStringVoidReceivedInvocations = []
        countlyMock.resetInstanceVoidCallsCount = 0
    }

    // MARK: - Tests

    @MainActor
    func testEnableTracking_succeeds() async throws {
        // When tracking is enabled.
        sut.enableTracking()

        // Then the service was started.
        let invocations = countlyMock.startAppKeyStringHostURLVoidReceivedInvocations

        guard invocations.count == 1 else {
            XCTFail("expected 1 invocation, got: \(invocations.count)")
            return
        }

        XCTAssertEqual(invocations[0].appKey, Scaffolding.config.appKey)
        XCTAssertEqual(invocations[0].host, Scaffolding.config.host)

        // Then no session has started yet.
        XCTAssertEqual(countlyMock.beginSessionVoidCallsCount, 0)
    }

    @MainActor
    func testDisableTracking_succeeds() async throws {
        // Given tracking is enabled.
        sut.enableTracking()
        resetMockInvocations()

        // When tracking is disabled.
        try sut.disableTracking()

        // Then any session was ended and the service was reset.
        XCTAssertEqual(countlyMock.endSessionVoidCallsCount, 1)
        XCTAssertEqual(countlyMock.resetInstanceVoidCallsCount, 1)

        // Then the user was cleared.
        let setUserInvocations = countlyMock.setUserValueValueStringForKeyKeyStringVoidReceivedInvocations

        guard setUserInvocations.count == 3 else {
            XCTFail("expected 3 invocation, got: \(setUserInvocations.count)")
            return
        }

        XCTAssertEqual(setUserInvocations[0].key, "team_team_id")
        XCTAssertEqual(setUserInvocations[0].value, nil)
        XCTAssertEqual(setUserInvocations[1].key, "team_user_type")
        XCTAssertEqual(setUserInvocations[1].value, nil)
        XCTAssertEqual(setUserInvocations[2].key, "team_team_size")
        XCTAssertEqual(setUserInvocations[2].value, nil)
    }

    @MainActor
    func testSwitchUser_user_is_same() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given a user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When switching to the same user.
        try sut.switchUser(Scaffolding.user)

        // Then the user was not switched again.
        XCTAssertEqual(countlyMock.endSessionVoidCallsCount, 0)
        XCTAssertEqual(countlyMock.changeDeviceIDIdStringMergeDataBoolVoidCallsCount, 0)
        XCTAssertEqual(countlyMock.setUserValueValueStringForKeyKeyStringVoidCallsCount, 0)
        XCTAssertEqual(countlyMock.beginSessionVoidCallsCount, 0)
    }

    @MainActor
    func testSwitchUser_succeeds() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given a user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When switching to a different user.
        try sut.switchUser(Scaffolding.userWithTeam)

        // Then the existing session was ended.
        XCTAssertEqual(countlyMock.endSessionVoidCallsCount, 1)

        // Then the device id was changed.
        let deviceChangeInvocations = countlyMock.changeDeviceIDIdStringMergeDataBoolVoidReceivedInvocations
        guard deviceChangeInvocations.count == 1 else {
            XCTFail("expected 1 device change invocation, got \(deviceChangeInvocations.count)")
            return
        }

        XCTAssertEqual(deviceChangeInvocations[0].id, Scaffolding.userWithTeam.trackingID.uuidString.lowercased())
        XCTAssertEqual(deviceChangeInvocations[0].mergeData, false)

        // Then the user details were set.
        let userSetInvocations = countlyMock.setUserValueValueStringForKeyKeyStringVoidReceivedInvocations
        guard userSetInvocations.count == 3 else {
            XCTFail("expected 3 user set invocations, got \(userSetInvocations.count)")
            return
        }

        let teamInfo = try XCTUnwrap(Scaffolding.userWithTeam.teamInfo)
        XCTAssertEqual(userSetInvocations[0].key, AnalyticsUserKey.teamID.rawValue)
        XCTAssertEqual(userSetInvocations[0].value, teamInfo.id)
        XCTAssertEqual(userSetInvocations[1].key, AnalyticsUserKey.teamRole.rawValue)
        XCTAssertEqual(userSetInvocations[1].value, teamInfo.role)
        XCTAssertEqual(userSetInvocations[2].key, AnalyticsUserKey.teamSize.rawValue)
        XCTAssertEqual(userSetInvocations[2].value, String(teamInfo.size.logRound()))

        // Then a new session was started.
        XCTAssertEqual(countlyMock.beginSessionVoidCallsCount, 1)
    }

    @MainActor
    func testUpdateCurrentUser_no_current_user() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given no current user.

        // When updating the current user.
        try sut.updateCurrentUser(Scaffolding.user)

        // Then the user was not updated.
        XCTAssertEqual(countlyMock.changeDeviceIDIdStringMergeDataBoolVoidCallsCount, 0)
        XCTAssertEqual(countlyMock.setUserValueValueStringForKeyKeyStringVoidCallsCount, 0)
    }

    @MainActor
    func testUpdateCurrentUser_no_change() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given a current user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When updating the current user with no change.
        try sut.updateCurrentUser(Scaffolding.user)

        // Then no user data changed.
        XCTAssertEqual(countlyMock.changeDeviceIDIdStringMergeDataBoolVoidCallsCount, 0)
        XCTAssertEqual(countlyMock.setUserValueValueStringForKeyKeyStringVoidCallsCount, 0)
    }

    @MainActor
    func testUpdateCurrentUser_with_change() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given a current user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When updating the current user.
        try sut.updateCurrentUser(Scaffolding.userWithTeam)

        // Then the device id was changed with a merge.
        let deviceChangeInvocations = countlyMock.changeDeviceIDIdStringMergeDataBoolVoidReceivedInvocations
        guard deviceChangeInvocations.count == 1 else {
            XCTFail("expected 1 device change invocation, got \(deviceChangeInvocations.count)")
            return
        }

        XCTAssertEqual(deviceChangeInvocations[0].id, Scaffolding.userWithTeam.trackingID.uuidString.lowercased())
        XCTAssertEqual(deviceChangeInvocations[0].mergeData, true)

        // Then the user details were set.
        let userSetInvocations = countlyMock.setUserValueValueStringForKeyKeyStringVoidReceivedInvocations
        guard userSetInvocations.count == 3 else {
            XCTFail("expected 3 user set invocations, got \(userSetInvocations.count)")
            return
        }

        let teamInfo = try XCTUnwrap(Scaffolding.userWithTeam.teamInfo)
        XCTAssertEqual(userSetInvocations[0].key, AnalyticsUserKey.teamID.rawValue)
        XCTAssertEqual(userSetInvocations[0].value, teamInfo.id)
        XCTAssertEqual(userSetInvocations[1].key, AnalyticsUserKey.teamRole.rawValue)
        XCTAssertEqual(userSetInvocations[1].value, teamInfo.role)
        XCTAssertEqual(userSetInvocations[2].key, AnalyticsUserKey.teamSize.rawValue)
        XCTAssertEqual(userSetInvocations[2].value, String(teamInfo.size.logRound()))
    }

    func testTrackEvent_service_not_configured() throws {
        // Given service is not configured.

        // When tracking an event.
        sut.trackEvent(Scaffolding.event)

        // Then no event was tracked.
        XCTAssertEqual(countlyMock.recordEventKeyStringSegmentationStringStringVoidCallsCount, 0)
    }

    @MainActor
    func testTrackEvent_no_current_user() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given no current user.

        // When tracking an event.
        sut.trackEvent(Scaffolding.event)

        // Then no event was tracked.
        XCTAssertEqual(countlyMock.recordEventKeyStringSegmentationStringStringVoidCallsCount, 0)
    }

    @MainActor
    func testTrackEvent_succeeds() async throws {
        // Given tracking is enabled.
        sut.enableTracking()

        // Given a current user.
        try sut.switchUser(Scaffolding.user)

        // When tracking an event.
        sut.trackEvent(Scaffolding.event)

        // Then a single event was tracked.
        let recordInvocations = countlyMock.recordEventKeyStringSegmentationStringStringVoidReceivedInvocations
        guard recordInvocations.count == 1 else {
            XCTFail("expected 1 recordInvocation, got \(recordInvocations.count)")
            return
        }

        XCTAssertEqual(recordInvocations[0].key, Scaffolding.event.name)

        XCTAssertEqual(
            recordInvocations[0].segmentation,
            Scaffolding.expectedSegmentation(for: Scaffolding.user)
        )
    }

}

private enum Scaffolding {

    @MainActor static let config = CountlyConfiguration(
        appKey: "SECRETKEY",
        host: URL(string: "www.example.com")!
    )

    static let user = AnalyticsUser(trackingID: UUID())

    static let userWithTeam = AnalyticsUser(
        trackingID: UUID(),
        teamInfo: TeamInfo(
            id: "teamID",
            role: "admin",
            size: 3
        )
    )

    static let event = AnalyticsEvent(
        name: "foo",
        segmentation: [segmentation]
    )

    static let segmentation = AnalyticsEvent.Segmentation(
        key: "bar",
        value: "car"
    )

    static let baseSegmentation: Set<AnalyticsEvent.Segmentation> = [
        .deviceModel("simulator"),
        .osVersion("iOS")
    ]

    static func expectedSegmentation(for user: AnalyticsUser) -> [String: String] {
        let segmentation = baseSegmentation.union([
            .Team.isSelfTeamMember(user.teamInfo != nil),
            segmentation
        ])

        return Dictionary(uniqueKeysWithValues: segmentation.map {
            ($0.key, $0.value)
        })
    }

}
