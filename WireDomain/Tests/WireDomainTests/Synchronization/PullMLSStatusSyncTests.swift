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

import WireDataModel
import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullMLSStatusSyncTests: XCTestCase {

    private var sut: PullMLSStatusSync!
    private var api: MockMLSAPI!
    private var store: MockBackendConfigLocalStoreProtocol!

    override func setUp() async throws {
        api = MockMLSAPI()
        store = MockBackendConfigLocalStoreProtocol()
        sut = PullMLSStatusSync(
            api: api,
            store: store
        )
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getBackendMLSPublicKeys_MockValue = Scaffolding.keys
        store.storeIsMLSEnabledStatusNewValue_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getBackendMLSPublicKeys_Invocations.count, 1)

        let storeInvocations = store.storeIsMLSEnabledStatusNewValue_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], true)
    }

    // Disabled: we have a problem with duplicate linking of WireNetwork which means
    // the mock error being thrown isn't caught in the sut even though it looks
    // like the same error.
    func testPull_EndpointUnavailable() async throws {
        // Mock
        api.getBackendMLSPublicKeys_MockError = MLSAPIError.unsupportedEndpointForAPIVersion
        store.storeIsMLSEnabledStatusNewValue_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getBackendMLSPublicKeys_Invocations.count, 1)

        let storeInvocations = store.storeIsMLSEnabledStatusNewValue_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], false)
    }

    // Disabled: we have a problem with duplicate linking of WireNetwork which means
    // the mock error being thrown isn't caught in the sut even though it looks
    // like the same error.
    func testPull_MLSNotEnabled() async throws {
        // Mock
        api.getBackendMLSPublicKeys_MockError = MLSAPIError.mlsNotEnabled
        store.storeIsMLSEnabledStatusNewValue_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getBackendMLSPublicKeys_Invocations.count, 1)

        let storeInvocations = store.storeIsMLSEnabledStatusNewValue_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], false)
    }

}

private enum Scaffolding {

    static let keys = BackendMLSPublicKeys(removal: .init(
        ed25519: "YVAl3Nsu27aNpNbYlPB6fi",
        p256: "BM036midcNiOMgny9m7N",
        p384: "BPSlomkR8K4BcFLGTDOJx",
        p521: "BAC3OmJi7rAPFAIXjU"
    ))

}
