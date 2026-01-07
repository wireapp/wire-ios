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

final class PushSupportedProtocolsSyncTests: XCTestCase {

    private var sut: PushSupportedProtocolsSync!
    private var api: MockSelfUserAPI!
    private var store: MockUserLocalStoreProtocol!

    override func setUp() async throws {
        api = MockSelfUserAPI()
        store = MockUserLocalStoreProtocol()
        sut = PushSupportedProtocolsSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPush() async throws {
        // Mock
        api.pushSupportedProtocols_MockMethod = { _ in }
        store.updateSelfUserSupportedProtocolsSupportedProtocols_MockMethod = { _ in }

        // When
        try await sut.push(supportedProtocols: Scaffolding.supportedProtocols)

        // Then
        let apiInvocations = api.pushSupportedProtocols_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0], Scaffolding.supportedProtocols)

        let storeInvocations = store.updateSelfUserSupportedProtocolsSupportedProtocols_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.supportedProtocols.toDomainModel())
    }

    func testPush_handles_mlsProtocolError() async throws {
        var attempts = 1
        // Mock
        api.pushSupportedProtocols_MockMethod = { _ in
            if attempts == 1 {
                attempts -= 1
                throw SelfUserAPIError.mlsProtocolError("Cannot remove MLS PROTOCOL")
            }

        }
        store.updateSelfUserSupportedProtocolsSupportedProtocols_MockMethod = { _ in }

        // When
        try await sut.push(supportedProtocols: Scaffolding.proteusSupportedProtocols)

        // Then
        let apiInvocations = api.pushSupportedProtocols_Invocations
        try XCTAssertCount(apiInvocations, count: 2)
        XCTAssertEqual(apiInvocations[0], Scaffolding.proteusSupportedProtocols)
        XCTAssertEqual(apiInvocations[1], Scaffolding.supportedProtocols, "Should push MLS PROTOCOL on retry")
        let storeInvocations = store.updateSelfUserSupportedProtocolsSupportedProtocols_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.supportedProtocols.toDomainModel())
    }
}

private enum Scaffolding {

    static let supportedProtocols: Set<WireNetwork.MessageProtocol> = [
        .proteus, .mls
    ]

    static let proteusSupportedProtocols: Set<WireNetwork.MessageProtocol> = [
        .proteus
    ]

}
