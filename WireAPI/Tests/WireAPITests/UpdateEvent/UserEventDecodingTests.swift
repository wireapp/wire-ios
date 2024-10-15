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

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = .init()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingClientAddEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserClientAdd")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.clientAdd(Scaffolding.clientAddEvent))
        )
    }

    func testDecodingClientRemoveEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserClientRemove")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.clientRemove(Scaffolding.clientRemoveEvent))
        )
    }

    func testDecodingUserConnectionEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserConnection")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.connection(Scaffolding.connectionEvent))
        )
    }

    func testDecodingUserContactJoinEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserContactJoin")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.contactJoin(Scaffolding.contactJoinEvent))
        )
    }

    func testDecodingUserEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserDelete")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.delete(Scaffolding.userDeleteEvent))
        )
    }

    func testDecodingUserLegalholdDisableEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserLegalholdDisable")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.legalholdDisable(Scaffolding.legalholdDisableEvent))
        )
    }

    func testDecodingUserLegalholdEnableEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserLegalholdEnable")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.legalholdEnable(Scaffolding.legalholdEnableEvent))
        )
    }

    func testDecodingUserLegalholdRequestEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserLegalholdRequest")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.legalholdRequest(Scaffolding.legalholdRequestEvent))
        )
    }

    func testDecodingUserPropertiesSetEvent_ReadReceipts() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserPropertiesSetReadReceipts")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.propertiesSet(Scaffolding.readReceiptsPropertiesSetEvent))
        )
    }

    func testDecodingUserPropertiesSetEvent_TypingIndicators() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserPropertiesSetTypingIndicators")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.propertiesSet(Scaffolding.typingIndicatorsPropertiesSetEvent))
        )
    }

    func testDecodingUserPropertiesSetEvent_ConversationLabels() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserPropertiesSetConversationLabels")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.propertiesSet(Scaffolding.conversationLabelsPropertiesSetEvent))
        )
    }

    func testDecodingUserPropertiesSetEvent_UnknownProperty() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserPropertiesSetUnknownProperty")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.propertiesSet(Scaffolding.unknownPropertiesSetEvent))
        )
    }

    func testDecodingUserPropertiesDeleteEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserPropertiesDelete")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.propertiesDelete(Scaffolding.propertiesDeleteEvent))
        )
    }

    func testDecodingUserUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "UserUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .user(.update(Scaffolding.updateEvent))
        )
    }

    private enum Scaffolding {

        static func fractionalDate(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.internetDateTime.date(from: string)!
        }

        static let clientAddEvent = UserClientAddEvent(
            client: UserClient(
                id: "2a1fd72806d84e26",
                type: .permanent,
                activationDate: fractionalDate(from: "2024-06-04T15:03:07.598Z"),
                label: "Alice's work phone",
                model: "iPhone 20",
                deviceClass: .phone,
                lastActiveDate: date(from: "2024-06-04T15:03:07Z"),
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
                senderID: UUID(uuidString: "67b39b90-bd3c-41dd-ab58-35905afda19c")!,
                receiverID: UUID(uuidString: "7fdaac60-68cc-4c3b-b337-8202506a2db6")!,
                receiverQualifiedID: QualifiedID(
                    uuid: UUID(uuidString: "7fdaac60-68cc-4c3b-b337-8202506a2db6")!,
                    domain: "example.com"
                ),
                conversationID: UUID(uuidString: "ef84379d-9bd6-432f-b2d6-ff636343596b")!,
                qualifiedConversationID: QualifiedID(
                    uuid: UUID(uuidString: "ef84379d-9bd6-432f-b2d6-ff636343596b")!,
                    domain: "example.com"
                ),
                lastUpdate: date(from: "2024-06-05T08:34:21Z"),
                status: .accepted
            )
        )

        static let contactJoinEvent = UserContactJoinEvent(name: "Alice McGee")

        static let userDeleteEvent = UserDeleteEvent(
            qualifiedUserID: QualifiedID(
                uuid: UUID(uuidString: "426525d3-81fc-467a-843a-1d1c375ca4b4")!,
                domain: "example.com"
            ),
            time: fractionalDate(from: "2021-05-12T10:52:02.671Z")
        )

        static let legalholdDisableEvent = UserLegalholdDisableEvent(userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!)

        static let legalholdEnableEvent = UserLegalholdEnableEvent(userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!)

        static let legalholdRequestEvent = UserLegalholdRequestEvent(
            userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!,
            clientID: "abcd1234",
            lastPrekey: Prekey(
                id: 12_345,
                base64EncodedKey: "foo"
            )
        )

        static let readReceiptsPropertiesSetEvent = UserPropertiesSetEvent(
            property: .areReadReceiptsEnabled(true)
        )

        static let typingIndicatorsPropertiesSetEvent = UserPropertiesSetEvent(
            property: .areTypingIndicatorsEnabled(true)
        )

        static let conversationLabelsPropertiesSetEvent = UserPropertiesSetEvent(
            property: .conversationLabels(
                [
                    ConversationLabel(
                        id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b0")!,
                        name: "Foo",
                        type: 0,
                        conversationIDs: [
                            UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
                            UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!
                        ]
                    ),
                    ConversationLabel(
                        id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE375")!,
                        name: nil,
                        type: 1,
                        conversationIDs: [
                            UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ffc")!,
                            UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf8")!
                        ]
                    )
                ]
            )
        )

        static let unknownPropertiesSetEvent = UserPropertiesSetEvent(
            property: .unknown(key: "SOME_UNKNOWN_KEY")
        )

        static let propertiesDeleteEvent = UserPropertiesDeleteEvent(key: "foo")

        static let updateEvent = UserUpdateEvent(
            userID: UUID(uuidString: "539d9183-32a5-4fc4-ba5c-4634454e7585")!,
            accentColorID: 2,
            name: "Alice McGee",
            handle: "alicemcgee",
            email: "alice@example.com",
            isSSOIDDeleted: true,
            assets: [
                UserAsset(
                    key: "abcdefg",
                    size: .complete,
                    type: .image
                )
            ],
            supportedProtocols: [
                .proteus,
                .mls
            ]
        )

    }

}
