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

    private let helper = EventDecodingAssertionHelper()

    func testDecodingClientAddEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserClientAdd",
            to: .user(.clientAdd(Scaffolding.clientAddEvent))
        )
    }

    func testDecodingClientRemoveEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserClientRemove",
            to: .user(.clientRemove(Scaffolding.clientRemoveEvent))
        )
    }

    func testDecodingUserConnectionEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserConnection",
            to: .user(.connection(Scaffolding.connectionEvent))
        )
    }

    func testDecodingUserContactJoinEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserContactJoin",
            to: .user(.contactJoin(Scaffolding.contactJoinEvent))
        )
    }

    func testDecodingUserEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserDelete",
            to: .user(.delete(Scaffolding.userDeleteEvent))
        )
    }

    func testDecodingUserLegalholdDisableEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserLegalholdDisable",
            to: .user(.legalholdDisable(Scaffolding.legalholdDisableEvent))
        )
    }

    func testDecodingUserLegalholdEnableEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserLegalholdEnable",
            to: .user(.legalholdEnable(Scaffolding.legalholdEnableEvent))
        )
    }

    func testDecodingUserLegalholdRequestEvent() throws {
        try helper.assertEventDecodingFromResource(
            named: "UserLegalholdRequest",
            to: .user(.legalholdRequest(Scaffolding.legalholdRequestEvent))
        )
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

        static let contactJoinEvent = UserContactJoinEvent(name: "Alice McGee")

        static let userDeleteEvent = UserDeleteEvent(
            userID: UUID(uuidString: "426525d3-81fc-467a-843a-1d1c375ca4b4")!,
            qualifiedUserID: QualifiedID(
                uuid: UUID(uuidString: "426525d3-81fc-467a-843a-1d1c375ca4b4")!,
                domain: "example.com"
            )
        )

        static let legalholdDisableEvent = UserLegalholdDisableEvent(userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!)

        static let legalholdEnableEvent = UserLegalholdEnableEvent(userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!)

        static let legalholdRequestEvent = UserLegalholdRequestEvent(
            userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!,
            clientID: "abcd1234",
            lastPrekey: Prekey(
                id: 12345,
                base64EncodedKey: "foo"
            )
        )

    }

}
