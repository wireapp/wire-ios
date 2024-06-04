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

@testable import WireAPI
import XCTest

final class UserEventDecodingTests: XCTestCase {

    func testDecodingClientAddEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "UserClientAdd")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .user(.clientAdd(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.clientAddEvent)
    }

    private enum Scaffolding {

        static let clientAddEvent = UserClientAddEvent(
            client: UserClient(
                id: "2a1fd72806d84e26",
                type: .permanent,
                activationDate: ISO8601DateFormatter.default.date(from: "2024-06-04T15:03:07.598Z")!,
                label: "Alice's work phone",
                model: "iPhone 20",
                deviceClass: .phone,
                lastActiveDate: ISO8601DateFormatter.default.date(from: "2024-06-04T15:03:07.598Z"),
                mlsPublicKeys: MLSPublicKeys(
                    ed25519: "ed25519_key",
                    ed448: "ed448_key",
                    p256: "p256_key",
                    p384: "p384_key",
                    p512: "p512_key"
                ),
                cookie: "cookieData",
                capabilities: [
                    .legalholdConsent
                ]
            )
        )

    }

}
