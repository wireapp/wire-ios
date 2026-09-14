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

@testable import WireNetwork
@testable import WireNetworkSupport

final class SystemSettingsAPITests: XCTestCase {

    func testGetSystemSettings_SuccessResponse_200_V18() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetSystemSettingsSuccessResponse")
        ])
        let sut = SystemSettingsAPIBuilder(networkService: networkService).makeAPI()

        // When
        let result = try await sut.getSystemSettings()

        // Then
        XCTAssertEqual(
            result,
            SystemSettings(
                nomadProfiles: true,
                setEnableMls: true,
                setRestrictUserCreation: false,
                ssoIdpChangeDetectionEnabled: true
            )
        )
    }

    func testGetSystemSettings_FailsToDecode_WhenARequiredFieldIsMissing() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetSystemSettingsMissingFieldResponse")
        ])
        let sut = SystemSettingsAPIBuilder(networkService: networkService).makeAPI()

        // Then
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.getSystemSettings()
        }
    }

}
