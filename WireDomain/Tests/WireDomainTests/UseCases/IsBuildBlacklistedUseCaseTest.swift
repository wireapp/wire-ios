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
import Testing
import WireNetwork
@testable import WireDomain
@testable import WireNetworkSupport

struct IsBuildBlacklistedUseCaseTest {

    let api: MockBlacklistAPI

    init() {
        self.api = MockBlacklistAPI()
        api.getBlacklist_MockValue = BuildNumberBlacklist(
            minimumLegalBuildNumber: "100",
            illegalBuildNumbers: ["50", "150", "200"]
        )
    }

    @Test(
        "Blacklisted versions",
        arguments: ["1", "50", "95", "98", "99", "150", "200"]
    )
    func blacklistedVersions(currentBuildNumber: String) async throws {
        // Given
        let sut = IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: currentBuildNumber,
            api: api
        )

        // When
        let isBlacklisted = await sut.invoke()

        // Then
        #expect(isBlacklisted == true)
    }

    @Test(
        "Allowed versions",
        arguments: ["100", "101", "149", "151", "199", "201"]
    )
    func allowedVersions(currentBuildNumber: String) async throws {
        // Given
        let sut = IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: currentBuildNumber,
            api: api
        )

        // When
        let isBlacklisted = await sut.invoke()

        // Then
        #expect(isBlacklisted == false)
    }

    @Test("Failures are equivalent to empty blacklist")
    func failuresAreEquivalentToEmptyBlacklist() async throws {
        // Given
        let sut = IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: "1",
            api: api
        )

        api.getBlacklist_MockError = "some error"

        // When
        let isBlacklisted = await sut.invoke()

        // Then
        #expect(isBlacklisted == false)
    }

}
