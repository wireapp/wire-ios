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

import WireTransport
import XCTest
@testable import WireSyncEngine

final class ZMUserSessionTests_AccessToken: ZMUserSessionTestsBase {
    func test_itRenewsAccessTokenAfterClientRegistration_StartingFromApiV3() {
        syncMOC.performAndWait {
            let selfClient = createSelfClient()

            for item in APIVersion.allCases {
                test_accessTokenRenewalAfterClientRegistration(
                    userClient: selfClient,
                    apiVersion: item,
                    shouldRenew: item > .v2
                )
            }
        }
    }

    func test_accessTokenRenewalAfterClientRegistration(
        userClient: UserClient,
        apiVersion: APIVersion,
        shouldRenew: Bool
    ) {
        // given
        defer {
            transportSession.renewAccessTokenCalls = []
        }
        BackendInfo.apiVersion = apiVersion

        // when
        sut.didRegisterSelfUserClient(userClient)

        // then
        if shouldRenew {
            XCTAssertEqual(transportSession.renewAccessTokenCalls.count, 1)
            XCTAssertEqual(transportSession.renewAccessTokenCalls.first, userClient.remoteIdentifier)
        } else {
            XCTAssertEqual(transportSession.renewAccessTokenCalls.count, 0)
        }
    }
}
