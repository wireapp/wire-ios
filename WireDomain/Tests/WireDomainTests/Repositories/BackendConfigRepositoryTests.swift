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

import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class BackendConfigRepositoryTests: XCTestCase {
    private var sut: BackendConfigRepository!
    private var mlsAPI: MockMLSAPI!
    private var backendConfigLocalStore: MockBackendConfigLocalStoreProtocol!

    override func setUp() async throws {
        mlsAPI = MockMLSAPI()
        backendConfigLocalStore = MockBackendConfigLocalStoreProtocol()
        sut = BackendConfigRepository(
            mlsAPI: mlsAPI,
            backendConfigLocalStore: backendConfigLocalStore
        )
    }

    override func tearDown() async throws {
        mlsAPI = nil
        backendConfigLocalStore = nil
        sut = nil
    }

    // MARK: - Tests

    func testPullMLSBackendStatus_MLSPublicKeysAreValid_It_Invokes_And_isMLSEnabledIsTrue() async {
        // Mock
        mlsAPI.getBackendMLSPublicKeys_MockValue = BackendMLSPublicKeys(
            removal: .init(
                ed25519: "YVAl3Nsu27aNpNbYlPB6fi",
                p256: "BM036midcNiOMgny9m7N",
                p384: "BPSlomkR8K4BcFLGTDOJx",
                p521: "BAC3OmJi7rAPFAIXjU"
            )
        )
        backendConfigLocalStore.storeIsMLSEnabledStatusNewValue_MockMethod = { newValue in
            self.backendConfigLocalStore.underlyingIsMLSEnabled = newValue
        }

        // When
        await sut.pullMLSBackendStatus()

        // Then
        XCTAssertEqual(mlsAPI.getBackendMLSPublicKeys_Invocations.count, 1)
        XCTAssertEqual(backendConfigLocalStore.storeIsMLSEnabledStatusNewValue_Invocations.count, 1)
        XCTAssertTrue(backendConfigLocalStore.isMLSEnabled)
    }

    func testPullMLSBackendStatus_MLSPublicKeysAreInvalid_It_Invokes_And_isMLSEnabledIsFalse() async {
        // Mock
        mlsAPI.getBackendMLSPublicKeys_MockValue = BackendMLSPublicKeys(
            removal: .init(
                ed25519: nil,
                p256: nil,
                p384: nil,
                p521: nil
            )
        )
        backendConfigLocalStore.storeIsMLSEnabledStatusNewValue_MockMethod = { newValue in
            self.backendConfigLocalStore.underlyingIsMLSEnabled = newValue
        }

        // When
        await sut.pullMLSBackendStatus()

        // Then
        XCTAssertEqual(mlsAPI.getBackendMLSPublicKeys_Invocations.count, 1)
        XCTAssertEqual(backendConfigLocalStore.storeIsMLSEnabledStatusNewValue_Invocations.count, 1)
        XCTAssertFalse(backendConfigLocalStore.isMLSEnabled)
    }
}
