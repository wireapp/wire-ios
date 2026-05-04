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

import WireFoundationSupport
import WireTestingPackage
import XCTest

@testable import WireNetwork

final class ServerTrustValidatorTests: XCTestCase {

    private var mockDateProvider: CurrentDateProvidingMock!

    override func setUp() async throws {
        mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T12:34:56Z")
    }

    override func tearDown() {
        mockDateProvider = nil
    }

    func testValidate_whenNoMatchingHosts() async throws {
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(rawKey: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ],
            currentDateProvider: mockDateProvider
        )

        try await sut.validate(trust: .other, host: "example.com")
    }

    func testValidate_whenInvalidServerTrust() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(rawKey: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ],
            currentDateProvider: mockDateProvider
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.evaluatingServerTrustFailed(errSecCreateChainFailed),
            when: { try await sut.validate(trust: .invalid, host: "prod-nginz-https.wire.com") }
        )
    }

    func testValidate_whenNoMatchingPublicKey() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(rawKey: PublicKeys.wire, hosts: [.equals("example.com")])
            ],
            currentDateProvider: mockDateProvider
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.noMatchingPublicKey,
            when: { try await sut.validate(trust: .other, host: "example.com") }
        )
    }

    func testValidate_beforeExpiration_UTC() async throws {
        let succeeded = try await testExpirationSucceeds(timestamp: "2025-04-09T23:59:59Z")
        XCTAssertTrue(succeeded)
    }

    func testValidate_beforeExpiration_localTime() async throws {
        let succeeded = try await testExpirationSucceeds(timestamp: "2025-04-10T01:59:59+02:00")
        XCTAssertTrue(succeeded)
    }

    func testValidate_afterExpiration_UTC() async throws {
        let succeeded = try await testExpirationSucceeds(timestamp: "2025-04-10T00:00:00Z")
        XCTAssertFalse(succeeded)
    }

    func testValidate_afterExpiration_localTime() async throws {
        let succeeded = try await testExpirationSucceeds(timestamp: "2025-04-10T02:00:00+02:00")
        XCTAssertFalse(succeeded)
    }

    /// Validates on the given timestamp and returns `true` if the validation succeeds, `false` otherwise.
    /// Any other error than `.evaluatingServerTrustFailed(errSecCertificateExpired)` is thrown.
    private func testExpirationSucceeds(timestamp: String) async throws -> Bool {
        do {
            // GIVEN
            mockDateProvider.now = try Date.ISO8601FormatStyle().parse(timestamp)

            let sut = ServerTrustValidator(
                pinnedKeys: [
                    try PinnedKey(rawKey: PublicKeys.wire, hosts: [.endsWith("wire.com")])
                ],
                currentDateProvider: mockDateProvider
            )

            // WHEN
            try await sut.validate(trust: .wire, host: "prod-nginz-https.wire.com")

            // THEN
            return true
        } catch ServerTrustValidator.Failure.evaluatingServerTrustFailed(errSecCertificateExpired) {
            // THEN
            return false
        }
    }

}
