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

    func testDecodingClientRemoveEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "UserClientRemove")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .user(.clientRemove(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.clientRemoveEvent)
    }

    func testDecodingUserConnectionEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "UserConnection")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .user(.connection(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.connectionEvent)
    }

    private enum Scaffolding {

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.default.date(from: string)!
        }

        static let clientAddEvent = UserClientAddEvent(
            client: UserClient(
                id: "2a1fd72806d84e26",
                type: .permanent,
                activationDate: date(from: "2024-06-04T15:03:07.598Z"),
                label: "Alice's work phone",
                model: "iPhone 20",
                deviceClass: .phone,
                lastActiveDate: date(from: "2024-06-04T15:03:07.598Z"),
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

        static let clientRemoveEvent = UserClientRemoveEvent(clientID: "2a1fd72806d84e26")

        static let connectionEvent = UserConnectionEvent(
            userName: "Alice McGee",
            connection: Connection(
                senderId: UUID(uuidString: "67b39b90-bd3c-41dd-ab58-35905afda19c")!,
                receiverId: UUID(uuidString: "7fdaac60-68cc-4c3b-b337-8202506a2db6")!,
                receiverQualifiedId: QualifiedID(
                    uuid: UUID(uuidString: "7fdaac60-68cc-4c3b-b337-8202506a2db6")!,
                    domain: "example.com"
                ),
                conversationId: UUID(uuidString: "ef84379d-9bd6-432f-b2d6-ff636343596b")!,
                qualifiedConversationId: QualifiedID(
                    uuid: UUID(uuidString: "ef84379d-9bd6-432f-b2d6-ff636343596b")!,
                    domain: "example.com"
                ),
                lastUpdate: date(from: "2024-06-05T08:34:21.766Z"),
                status: .accepted
            )
        )

    }

}
