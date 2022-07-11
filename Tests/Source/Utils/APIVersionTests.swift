// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

final class APIVersionTests: XCTestCase {

    override func tearDown() {
        APIVersion.setVersions(production: [], development: [])
    }

    // MARK: - Setting versions

    func test_SettingVersions_AlsoSetsHighestProductionVersion() {
        // When
        APIVersion.setVersions(production: [.v0, .v1], development: [])

        // Then
        XCTAssertEqual(APIVersion.highestProductionVersion, .v1)
    }

    func test_SettingVersions_ClearsPreferredVersion_IfItIsNoLongerValid() {
        // Given
        APIVersion.preferredVersion = .v1

        // When
        APIVersion.setVersions(production: [.v0], development: [])

        // Then
        XCTAssertNil(APIVersion.preferredVersion)
    }

    func test_SettingVersions_DoesNotClearPreferredVersion_IfItIsStillValid() {
        // Given
        APIVersion.preferredVersion = .v1

        // When
        APIVersion.setVersions(production: [.v0], development: [.v1])

        // Then
        XCTAssertEqual(APIVersion.preferredVersion, .v1)
    }

    // MARK: - Current version

    func test_CurrentVersion_IsPreferredVersion() {
        // Given
        APIVersion.preferredVersion = .v1

        // When
        APIVersion.setVersions(production: [.v0], development: [.v1])

        // Then
        XCTAssertEqual(APIVersion.current, .v1)
    }

    func test_CurrentVersion_IsHighestProductionVersion_IfThereIsNoPreferredVersion() {
        // Given
        APIVersion.preferredVersion = nil

        // When
        APIVersion.setVersions(production: [.v0], development: [.v1])

        // Then
        XCTAssertEqual(APIVersion.current, .v0)
    }

    func test_CurrentVersion_IsNil_IfThereAreNoVersions() {
        // When
        APIVersion.setVersions(production: [], development: [])

        // Then
        XCTAssertNil(APIVersion.current)
    }

}
