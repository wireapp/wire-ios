//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

class AnalyticsServiceTests: XCTestCase {

    private var sut: AnalyticsService!
    private var countlyMock: MockCountlyProtocol!

    override func setUpWithError() throws {
        countlyMock = .init()
        sut = AnalyticsService(
            config: Scaffolding.config,
            baseSegmentation: Scaffolding.baseSegmentation,
            countlyProvider: { self.countlyMock }
        )

        countlyMock.startAppKeyHost_MockMethod = { _, _ in }
        countlyMock.resetInstance_MockMethod = {}
        countlyMock.endSession_MockMethod = {}
        countlyMock.beginSession_MockMethod = {}
        countlyMock.changeDeviceIDMergeData_MockMethod = { _, _ in }
        countlyMock.setUserValueForKey_MockMethod = { _, _ in }
        countlyMock.recordEventSegmentation_MockMethod = { _, _ in }
    }

    override func tearDown() {
        countlyMock = nil
        sut = nil
    }

    func resetMockInvocations() {
        countlyMock.startAppKeyHost_Invocations = []
        countlyMock.endSession_Invocations = []
        countlyMock.beginSession_Invocations = []
        countlyMock.changeDeviceIDMergeData_Invocations = []
        countlyMock.setUserValueForKey_Invocations = []
        countlyMock.resetInstance_Invocations = []
    }

    // MARK: - Tests

    @MainActor
    func testEnableTracking_service_is_not_configured() async throws {
        // Given a service with no config.
        let sut = AnalyticsService(
            config: nil,
            baseSegmentation: Scaffolding.baseSegmentation,
            countlyProvider: { self.countlyMock }
        )

        do {
            // When tracking is enabled.
            try await sut.enableTracking()
            XCTFail("expected error AnalyticsServiceError.serviceIsNotConfigured")
        } catch AnalyticsServiceError.serviceIsNotConfigured {
            // Then
        }
    }

    @MainActor
    func testEnableTracking_succeeds() async throws {
        // When tracking is enabled.
        try await sut.enableTracking()

        // Then the service was started.
        let invocations = countlyMock.startAppKeyHost_Invocations

        guard invocations.count == 1 else {
            XCTFail("expected 1 invocation, got: \(invocations.count)")
            return
        }

        XCTAssertEqual(invocations[0].appKey, Scaffolding.config.secretKey)
        XCTAssertEqual(invocations[0].host, Scaffolding.config.serverHost)

        // Then no session has started yet.
        XCTAssertEqual(countlyMock.beginSession_Invocations.count, 0)
    }

    func testDisableTracking_service_is_not_configured() throws {
        // Given sut was not enabled.

        // When tracking is disabled.
        XCTAssertThrowsError(try sut.disableTracking()) {
            // Then it throws an error.
            guard case AnalyticsServiceError.serviceIsNotConfigured = $0 else {
                XCTFail("unexpected error: \($0)")
                return
            }
        }
    }

    @MainActor
    func testDisableTracking_succeeds() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()
        resetMockInvocations()

        // When tracking is disabled.
        try sut.disableTracking()

        // Then any session was ended and the service was reset.
        XCTAssertEqual(countlyMock.endSession_Invocations.count, 1)
        XCTAssertEqual(countlyMock.resetInstance_Invocations.count, 1)

        // Then the user was cleared.
        let setUserInvocations = countlyMock.setUserValueForKey_Invocations

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

    func testSwitchUser_tracking_disabled() throws {
        // Given sut is not enabled.

        do {
            // When switching to a user.
            try sut.switchUser(Scaffolding.user)
            XCTFail("expected error AnalyticsServiceError.serviceIsNotConfigured")
        } catch AnalyticsServiceError.serviceIsNotConfigured {
            // Then
        }
    }

    @MainActor
    func testSwitchUser_user_is_same() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given a user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When switching to the same user.
        try sut.switchUser(Scaffolding.user)

        // Then the user was not switched again.
        XCTAssertEqual(countlyMock.endSession_Invocations.count, 0)
        XCTAssertEqual(countlyMock.changeDeviceIDMergeData_Invocations.count, 0)
        XCTAssertEqual(countlyMock.setUserValueForKey_Invocations.count, 0)
        XCTAssertEqual(countlyMock.beginSession_Invocations.count, 0)
    }

    @MainActor
    func testSwitchUser_succeeds() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given a user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When switching to a different user.
        try sut.switchUser(Scaffolding.userWithTeam)

        // Then the existing session was ended.
        XCTAssertEqual(countlyMock.endSession_Invocations.count, 1)

        // Then the device id was changed.
        let deviceChangeInvocations = countlyMock.changeDeviceIDMergeData_Invocations
        guard deviceChangeInvocations.count == 1 else {
            XCTFail("expected 1 device change invocation, got \(deviceChangeInvocations.count)")
            return
        }

        XCTAssertEqual(deviceChangeInvocations[0].id, Scaffolding.userWithTeam.analyticsIdentifier)
        XCTAssertEqual(deviceChangeInvocations[0].mergeData, false)

        // Then the user details were set.
        let userSetInvocations = countlyMock.setUserValueForKey_Invocations
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
        XCTAssertEqual(countlyMock.beginSession_Invocations.count, 1)
    }

    @MainActor
    func testUpdateCurrentUser_no_current_user() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given no current user.

        // When updating the current user.
        try sut.updateCurrentUser(Scaffolding.user)

        // Then the user was not updated.
        XCTAssertEqual(countlyMock.changeDeviceIDMergeData_Invocations.count, 0)
        XCTAssertEqual(countlyMock.setUserValueForKey_Invocations.count, 0)
    }

    @MainActor
    func testUpdateCurrentUser_no_change() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given a current user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When updating the current user with no change.
        try sut.updateCurrentUser(Scaffolding.user)

        // Then no user data changed.
        XCTAssertEqual(countlyMock.changeDeviceIDMergeData_Invocations.count, 0)
        XCTAssertEqual(countlyMock.setUserValueForKey_Invocations.count, 0)
    }

    @MainActor
    func testUpdateCurrentUser_with_change() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given a current user is set.
        try sut.switchUser(Scaffolding.user)
        resetMockInvocations()

        // When updating the current user.
        try sut.updateCurrentUser(Scaffolding.userWithTeam)

        // Then the device id was changed with a merge.
        let deviceChangeInvocations = countlyMock.changeDeviceIDMergeData_Invocations
        guard deviceChangeInvocations.count == 1 else {
            XCTFail("expected 1 device change invocation, got \(deviceChangeInvocations.count)")
            return
        }

        XCTAssertEqual(deviceChangeInvocations[0].id, Scaffolding.userWithTeam.analyticsIdentifier)
        XCTAssertEqual(deviceChangeInvocations[0].mergeData, true)

        // Then the user details were set.
        let userSetInvocations = countlyMock.setUserValueForKey_Invocations
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
        XCTAssertEqual(countlyMock.recordEventSegmentation_Invocations.count, 0)
    }

    @MainActor
    func testTrackEvent_no_current_user() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given no current user.

        // When tracking an event.
        sut.trackEvent(Scaffolding.event)

        // Then no event was tracked.
        XCTAssertEqual(countlyMock.recordEventSegmentation_Invocations.count, 0)
    }

    @MainActor
    func testTrackEvent_succeeds() async throws {
        // Given tracking is enabled.
        try await sut.enableTracking()

        // Given a current user.
        try sut.switchUser(Scaffolding.user)

        // When tracking an event.
        sut.trackEvent(Scaffolding.event)

        // Then a single event was tracked.
        let recordInvocations = countlyMock.recordEventSegmentation_Invocations
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

    static let config = AnalyticsService.Config(
        secretKey: "SECRETKEY",
        serverHost: URL(string: "www.example.com")!
    )

    static let user = AnalyticsUser(analyticsIdentifier: "user1")

    static let userWithTeam = AnalyticsUser(
        analyticsIdentifier: "user2",
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
