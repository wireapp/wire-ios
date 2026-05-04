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

import WireNetwork
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class PushSupportedProtocolsUseCaseTests: XCTestCase {

    private var sut: PushSupportedProtocolsUseCase!
    private var mockPushSupportedProtocolsSync: MockPushSupportedProtocolsSyncProtocol!
    private var calculateSupportedProtocolsUseCase: MockCalculateSupportedProtocolsUseCaseProtocol!

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()
        mockPushSupportedProtocolsSync = MockPushSupportedProtocolsSyncProtocol()
        calculateSupportedProtocolsUseCase = MockCalculateSupportedProtocolsUseCaseProtocol()

        sut = PushSupportedProtocolsUseCase(
            pushSupportedProtocolsSync: mockPushSupportedProtocolsSync,
            calculateSupportedProtocolsUseCase: calculateSupportedProtocolsUseCase
        )

    }

    override func tearDown() async throws {
        try await super.tearDown()
        mockPushSupportedProtocolsSync = nil
        calculateSupportedProtocolsUseCase = nil
    }

    // MARK: - Tests

    func test_PushSupportedProtocols_It_Invokes_Sync_Method() async throws {
        // Given
        let supportedProtocols = Set([WireNetwork.MessageProtocol.mls, .proteus])
        calculateSupportedProtocolsUseCase.invoke_MockValue = supportedProtocols
        mockPushSupportedProtocolsSync.pushSupportedProtocols_MockMethod = { _ in }

        try await sut.invoke()
        let pushedProtocols = try XCTUnwrap(mockPushSupportedProtocolsSync.pushSupportedProtocols_Invocations.last)
        // Then
        XCTAssertEqual(supportedProtocols, pushedProtocols)
    }
}
