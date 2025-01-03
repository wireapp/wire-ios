//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireTestingPackage
import XCTest

@testable import WireAPI

final class ServerTrustValidatorTests: XCTestCase {

    func testValidate_whenNoMatchingHosts() async throws {
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ]
        )

        try await sut.validate(trust: .other, host: "example.com")
    }

    func testValidate_whenInvalidServerTrust() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
            ]
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.evaluatingServerTrustFailed,
            when: { try await sut.validate(trust: .invalid, host: "prod-nginz-https.wire.com") }
        )
    }

    func testValidate_whenNoMatchingPublicKey() async throws {
        // GIVEN
        let sut = ServerTrustValidator(
            pinnedKeys: [
                try PinnedKey(key: PublicKeys.wire, hosts: [.equals("example.com")])
            ]
        )

        // WHEN, THEN
        await XCTAssertThrowsErrorAsync(
            ServerTrustValidator.Failure.noMatchingPublicKey,
            when: { try await sut.validate(trust: .other, host: "example.com") }
        )
    }

}
