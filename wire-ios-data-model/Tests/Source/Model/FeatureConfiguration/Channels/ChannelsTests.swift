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

@testable import WireDataModel

final class ChannelsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsEnabled() {
        // given, when, then
        XCTAssertTrue(Feature.Channels(status: .enabled).isEnabled)
        XCTAssertFalse(Feature.Channels(status: .disabled).isEnabled)
    }

    func testCanCreateChannels_whenOwner() {
        typealias TestCase = (
            status: Feature.Status,
            permission: Feature.Channels.Config.ChannelsPermision,
            expectedResult: Bool
        )

        // given
        let testCases: [TestCase] = [
            (.enabled, .everyone, true),
            (.enabled, .teamMembers, true),
            (.enabled, .admins, true),
  	
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: testCase.status,
                config: .init(allowedToCreateChannels: testCase.permission)
            )

            // then
            XCTAssertEqual(feature.canCreateChannels(role: .owner), testCase.expectedResult)
        }
    }

    func testCanCreateChannels_whenTrue() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermision)

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
            (.partner, .everyone),
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(allowedToCreateChannels: testCase.permission)
            )

            // then
            XCTAssertTrue(feature.canCreateChannels(role: testCase.teamRole))
        }
    }

    func testCanCreateChannels_whenFalse() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermision)

        // given
        let testCases: [TestCase] = [
            (.member, .admins),
            (.partner, .teamMembers),
            (.partner, .admins),
            (.none, .everyone),
            (.none, .teamMembers),
            (.none, .admins),
        ]

        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(allowedToCreateChannels: testCase.permission)
            )

            // then
            XCTAssertFalse(feature.canCreateChannels(role: testCase.teamRole))
        }
    }

    func testCanOpenChannels_whenTrue() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermision)

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
            (.partner, .everyone),
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(allowedToOpenChannels: testCase.permission)
            )

            // then
            XCTAssertTrue(feature.canOpenChannels(role: testCase.teamRole))
        }
    }

    func testCanOpenChannels_whenFalse() {
        typealias TestCase = (teamRole: TeamRole, permission: Feature.Channels.Config.ChannelsPermision)

        // given
        let testCases: [TestCase] = [
            (.member, .admins),
            (.partner, .teamMembers),
            (.partner, .admins),
            (.none, .everyone),
            (.none, .teamMembers),
            (.none, .admins),
        ]

        // when
        for testCase in testCases {
            let feature = Feature.Channels(
                status: .enabled,
                config: .init(allowedToOpenChannels: testCase.permission)
            )

            XCTAssertFalse(feature.canOpenChannels(role: testCase.teamRole))
        }
    }

}
