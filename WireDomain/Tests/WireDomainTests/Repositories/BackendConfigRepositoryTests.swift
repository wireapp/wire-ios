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

import WireAPISupport
import XCTest
@testable import WireAPI
@testable import WireDomain

final class BackendConfigRepositoryTests: XCTestCase {
    private var sut: BackendConfigRepository!
    private var backendInfoAPI: MockBackendInfoAPI!
    private let storage = UserDefaults.standard
    private let key = "isMLSEnabled"

    override func setUp() async throws {
        backendInfoAPI = MockBackendInfoAPI()
        sut = BackendConfigRepository(backendInfoAPI: backendInfoAPI)
    }

    override func tearDown() async throws {
        backendInfoAPI = nil
        sut = nil
    }

    // MARK: - Tests

    func testPullMLSBackendStatus_MLSPublicKeysAreValid_It_Invokes_And_isMLSEnabledIsTrue() async {
        // Mock
        backendInfoAPI.getBackendMLSPublicKeys_MockValue = BackendMLSPublicKeys(
            removal: MLSPublicKeys.init(
                ed25519: "YVAl3Nsu27aNpNbYlPB6fi",
                ed448: nil,
                p256: "BM036midcNiOMgny9m7N",
                p384: "BPSlomkR8K4BcFLGTDOJx",
                p512: "BAC3OmJi7rAPFAIXjU")
        )

        // When
        await sut.pullMLSBackendStatus()

        // Then
        XCTAssertEqual(backendInfoAPI.getBackendMLSPublicKeys_Invocations.count, 1)
        XCTAssertTrue(storage.bool(forKey: key))
    }

    func testPullMLSBackendStatus_MLSPublicKeysAreInvalid_It_Invokes_And_isMLSEnabledIsFalse() async {
        // Mock
        backendInfoAPI.getBackendMLSPublicKeys_MockValue = BackendMLSPublicKeys(
            removal: MLSPublicKeys.init(
                ed25519: nil,
                ed448: nil,
                p256: nil,
                p384: nil,
                p512: nil)
        )

        // When
        await sut.pullMLSBackendStatus()

        // Then
        XCTAssertEqual(backendInfoAPI.getBackendMLSPublicKeys_Invocations.count, 1)
        XCTAssertFalse(storage.bool(forKey: key))
    }
}
