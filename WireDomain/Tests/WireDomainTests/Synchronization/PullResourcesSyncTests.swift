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
@testable import WireDomain
@testable import WireDomainSupport

final class PullResourcesSyncTests: XCTestCase {

    private var sut: PullResourcesSync!

    private var pullSelfUserSync: MockPullSelfUserSyncProtocol!
    private var pullSelfUserClientsSync: MockPullSelfUserClientsSyncProtocol!
    private var pullSelfUserSettingsSync: MockPullSelfUserSettingsSyncProtocol!
    private var pullSelfTeamSync: MockPullSelfTeamSyncProtocol!
    private var pullSelfTeamRolesSync: MockPullSelfTeamRolesSyncProtocol!
    private var pullSelfTeamMembersSync: MockPullSelfTeamMembersSyncProtocol!
    private var pullSelfLegalholdInfoSync: MockPullSelfLegalholdInfoSyncProtocol!
    private var pullUserConnectionsSync: MockPullUserConnectionsSyncProtocol!
    private var pullAllConversationsSync: MockPullAllConversationsSyncProtocol!
    private var pullKnownUsersSync: MockPullKnownUsersSyncProtocol!
    private var pullConversationLabelsSync: MockPullConversationLabelsSyncProtocol!
    private var pullAllFeatureConfigsSync: MockPullAllFeatureConfigsSyncProtocol!
    private var pullMLSStatusSync: MockPullMLSStatusSyncProtocol!

    override func setUp() async throws {
        pullSelfUserSync = MockPullSelfUserSyncProtocol()
        pullSelfUserClientsSync = MockPullSelfUserClientsSyncProtocol()
        pullSelfUserSettingsSync = MockPullSelfUserSettingsSyncProtocol()
        pullSelfTeamSync = MockPullSelfTeamSyncProtocol()
        pullSelfTeamRolesSync = MockPullSelfTeamRolesSyncProtocol()
        pullSelfTeamMembersSync = MockPullSelfTeamMembersSyncProtocol()
        pullSelfLegalholdInfoSync = MockPullSelfLegalholdInfoSyncProtocol()
        pullUserConnectionsSync = MockPullUserConnectionsSyncProtocol()
        pullAllConversationsSync = MockPullAllConversationsSyncProtocol()
        pullKnownUsersSync = MockPullKnownUsersSyncProtocol()
        pullConversationLabelsSync = MockPullConversationLabelsSyncProtocol()
        pullAllFeatureConfigsSync = MockPullAllFeatureConfigsSyncProtocol()
        pullMLSStatusSync = MockPullMLSStatusSyncProtocol()

        sut = PullResourcesSync(
            pullSelfUserSync: pullSelfUserSync,
            pullSelfUserClientsSync: pullSelfUserClientsSync,
            pullSelfUserSettingsSync: pullSelfUserSettingsSync,
            pullSelfTeamSync: pullSelfTeamSync,
            pullSelfTeamRolesSync: pullSelfTeamRolesSync,
            pullSelfTeamMembersSync: pullSelfTeamMembersSync,
            pullSelfLegalholdInfoSync: pullSelfLegalholdInfoSync,
            pullUserConnectionsSync: pullUserConnectionsSync,
            pullAllConversationsSync: pullAllConversationsSync,
            pullKnownUsersSync: pullKnownUsersSync,
            pullConversationLabelsSync: pullConversationLabelsSync,
            pullAllFeatureConfigsSync: pullAllFeatureConfigsSync,
            pullMLSStatusSync: pullMLSStatusSync
        )
    }

    override func tearDown() async throws {
        pullSelfUserSync = nil
        pullSelfTeamSync = nil
        pullSelfUserSettingsSync = nil
        pullSelfTeamSync = nil
        pullSelfTeamRolesSync = nil
        pullSelfTeamMembersSync = nil
        pullSelfLegalholdInfoSync = nil
        pullUserConnectionsSync = nil
        pullAllConversationsSync = nil
        pullKnownUsersSync = nil
        pullConversationLabelsSync = nil
        pullAllFeatureConfigsSync = nil
        pullMLSStatusSync = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        pullSelfUserSync.pull_MockValue = (
            id: Scaffolding.userID,
            domain: Scaffolding.domain,
            teamID: Scaffolding.teamID
        )
        pullSelfUserClientsSync.pull_MockMethod = {}
        pullSelfUserSettingsSync.pull_MockMethod = {}
        pullSelfTeamSync.pullSelfTeamID_MockMethod = { _ in }
        pullSelfTeamRolesSync.pullSelfTeamID_MockMethod = { _ in }
        pullSelfTeamMembersSync.pullSelfTeamID_MockMethod = { _ in }
        pullSelfLegalholdInfoSync.pullSelfTeamID_MockMethod = { _ in }
        pullUserConnectionsSync.pull_MockMethod = {}
        pullAllConversationsSync.pull_MockMethod = {}
        pullKnownUsersSync.pull_MockMethod = {}
        pullConversationLabelsSync.pull_MockMethod = {}
        pullAllFeatureConfigsSync.pull_MockMethod = {}
        pullMLSStatusSync.pull_MockMethod = {}

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(pullSelfUserSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullSelfUserClientsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullSelfUserSettingsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullSelfTeamSync.pullSelfTeamID_Invocations, [Scaffolding.teamID])
        XCTAssertEqual(pullSelfTeamRolesSync.pullSelfTeamID_Invocations, [Scaffolding.teamID])
        XCTAssertEqual(pullSelfTeamMembersSync.pullSelfTeamID_Invocations, [Scaffolding.teamID])
        XCTAssertEqual(pullSelfLegalholdInfoSync.pullSelfTeamID_Invocations, [Scaffolding.teamID])
        XCTAssertEqual(pullUserConnectionsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullAllConversationsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullKnownUsersSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullConversationLabelsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullAllFeatureConfigsSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullMLSStatusSync.pull_Invocations.count, 1)
    }

    func testPull_Resources_Are_Called_In_Right_Order() async throws {
        // Given
        var callOrder: [String] = []

        // Mock
        pullSelfUserSync.pull_MockMethod = {
            callOrder.append("pullSelfUserSync")
            return (
                id: Scaffolding.userID,
                domain: Scaffolding.domain,
                teamID: Scaffolding.teamID
            )
        }

        pullSelfUserClientsSync.pull_MockMethod = {
            callOrder.append("pullSelfUserClientsSync")
        }

        pullSelfUserSettingsSync.pull_MockMethod = {
            callOrder.append("pullSelfUserSettingsSync")
        }

        pullSelfTeamSync.pullSelfTeamID_MockMethod = { _ in
            callOrder.append("pullSelfTeamSync")
        }

        pullSelfTeamRolesSync.pullSelfTeamID_MockMethod = { _ in
            callOrder.append("pullSelfTeamRolesSync")
        }

        pullSelfTeamMembersSync.pullSelfTeamID_MockMethod = { _ in
            callOrder.append("pullSelfTeamMembersSync")
        }

        pullSelfLegalholdInfoSync.pullSelfTeamID_MockMethod = { _ in
            callOrder.append("pullSelfLegalholdInfoSync")
        }

        pullUserConnectionsSync.pull_MockMethod = {
            callOrder.append("pullUserConnectionsSync")
        }

        pullAllConversationsSync.pull_MockMethod = {
            callOrder.append("pullAllConversationsSync")
        }

        pullKnownUsersSync.pull_MockMethod = {
            callOrder.append("pullKnownUsersSync")
        }

        pullConversationLabelsSync.pull_MockMethod = {
            callOrder.append("pullConversationLabelsSync")
        }

        pullAllFeatureConfigsSync.pull_MockMethod = {
            callOrder.append("pullAllFeatureConfigsSync")
        }

        pullMLSStatusSync.pull_MockMethod = {
            callOrder.append("pullMLSStatusSync")
        }

        // When
        try await sut.pull()

        // Then, assert resources are called in right order.
        XCTAssertEqual(callOrder, [
            "pullUserConnectionsSync",
            "pullAllConversationsSync",
            "pullKnownUsersSync",
            "pullSelfUserSync",
            "pullSelfUserClientsSync",
            "pullSelfUserSettingsSync",
            "pullSelfTeamSync",
            "pullSelfTeamRolesSync",
            "pullSelfTeamMembersSync",
            "pullSelfLegalholdInfoSync",
            "pullConversationLabelsSync",
            "pullAllFeatureConfigsSync",
            "pullMLSStatusSync"
        ])
    }

}

private enum Scaffolding {

    static let userID = UUID()
    static let domain = "wire.com"
    static let teamID = UUID()

}
