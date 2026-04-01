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

@testable import WireDataModel

final class ChannelsTests: XCTestCase {

    func testIsEnabled() {
        // given, when, then
        XCTAssertTrue(Feature.Channels(status: .enabled).isEnabled)
        XCTAssertFalse(Feature.Channels(status: .disabled).isEnabled)
    }

    func testPermissions_whenStatusEnabledAndReturningTrue() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermission)

        // given
        let testCases: [TestCase] = [
            (.owner, .everyone),
            (.owner, .teamMembers),
            (.owner, .admins),
            (.admin, .everyone),
            (.admin, .teamMembers),
            (.admin, .admins),
            (.member, .everyone),
            (.member, .teamMembers),
            (.partner, .everyone)
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(
                    allowedToCreateChannels: testCase.permission,
                    allowedToOpenChannels: testCase.permission
                )
            )

            // then
            XCTAssertTrue(feature.canCreateChannels(role: testCase.teamRole))
            XCTAssertTrue(feature.canOpenChannels(role: testCase.teamRole))
        }
    }

    func testPermissions_whenStatusEnabledAndReturningFalse() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermission)

        // given
        let testCases: [TestCase] = [
            (.member, .admins),
            (.partner, .teamMembers),
            (.partner, .admins),
            (.none, .everyone),
            (.none, .teamMembers),
            (.none, .admins)
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(
                    allowedToCreateChannels: testCase.permission,
                    allowedToOpenChannels: testCase.permission
                )
            )

            // then
            XCTAssertFalse(feature.canCreateChannels(role: testCase.teamRole))
            XCTAssertFalse(feature.canOpenChannels(role: testCase.teamRole))
        }
    }

    func testPermissions_whenStatusDisabled() {
        // given
        let status: Feature.Status = .disabled
        let teamRoles: [TeamRole] = [.owner, .admin, .member, .partner, .none]
        let permissions: [Feature.Channels.Config.ChannelsPermission] = [.everyone, .teamMembers, .admins]

        for teamRole in teamRoles {
            for permission in permissions {
                // when
                let feature = Feature.Channels(
                    status: status,
                    config: .init(allowedToCreateChannels: permission, allowedToOpenChannels: permission)
                )

                // then
                XCTAssertFalse(feature.canCreateChannels(role: teamRole))
                XCTAssertFalse(feature.canOpenChannels(role: teamRole))
            }
        }
    }

}
