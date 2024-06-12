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

final class ConversationEventDecodingTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = .defaultDecoder
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingConversationAccessUpdateEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationAccessUpdate")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.accessUpdate(Scaffolding.accessUpdateEvent))
        )
    }

    func testDecodingConversationCodeUpdateEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationCodeUpdate")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.codeUpdate(Scaffolding.codeUpdateEvent))
        )
    }

    func testDecodingConversationCreateEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationCreate")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.create(Scaffolding.createEvent))
        )
    }

    func testDecodingConversationDeleteEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationDelete")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.delete(Scaffolding.deleteEvent))
        )
    }

    func testDecodingConversationMemberJoinEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationMemberJoin")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.memberJoin(Scaffolding.memberJoinEvent))
        )
    }

    private enum Scaffolding {

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.default.date(from: string)!
        }

        static let conversationID = ConversationID(
            uuid: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
            domain: "example.com"
        )

        static let senderID = UserID(
            uuid: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
            domain: "example.com"
        )

        static let accessUpdateEvent = ConversationAccessUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            accessModes: [.private, .invite, .link, .code],
            accessRoles: [.teamMember, .nonTeamMember, .guest, .service],
            legacyAccessRole: .nonActivated
        )

        static let codeUpdateEvent = ConversationCodeUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            uri: "www.example.com",
            key: "key",
            code: "123",
            isPasswordProtected: true
        )

        static let createEvent = ConversationCreateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: date(from: "2024-06-04T15:03:07.598Z"),
            conversation: Conversation(
                id: conversationID.uuid,
                qualifiedID: conversationID,
                teamID: UUID(uuidString: "acfb3399-5be5-4cee-b896-1230576c94a2")!,
                type: .group,
                messageProtocol: .proteus,
                mlsGroupID: "group_id",
                cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                epoch: 123,
                epochTimestamp: date(from: "2024-06-04T15:03:07.598Z"),
                creator: UUID(uuidString: "6d88b1b9-f882-4990-ade5-86643fc6006e")!,
                members: Conversation.Members(
                    others: [
                        Conversation.Member(
                            qualifiedID: QualifiedID(
                                uuid: UUID(uuidString: "2accd221-c35e-4806-a3dd-30718cff5230")!,
                                domain: "example.com"
                            ),
                            id: UUID(uuidString: "2accd221-c35e-4806-a3dd-30718cff5230")!,
                            qualifiedTarget: nil,
                            target: nil,
                            conversationRole: "member",
                            service: nil,
                            archived: nil,
                            archivedReference: nil,
                            hidden: nil,
                            hiddenReference: nil,
                            mutedStatus: nil,
                            mutedReference: nil
                        )
                    ],
                    selfMember: Conversation.Member(
                        qualifiedID: QualifiedID(
                            uuid: UUID(uuidString: "04162d93-2e13-4787-87b5-60ac601fb3b3")!,
                            domain: "example.com"
                        ),
                        id: UUID(uuidString: "04162d93-2e13-4787-87b5-60ac601fb3b3")!,
                        qualifiedTarget: nil,
                        target: nil,
                        conversationRole: "admin",
                        service: Service(
                            id: UUID(uuidString: "a728282b-795d-4087-a1b5-c79ca0b56cd0")!,
                            provider: UUID(uuidString: "69322b27-4fb8-41b6-add4-7b4ecc9e0c73")!
                        ),
                        archived: true,
                        archivedReference: date(from: "2024-06-04T15:03:07.598Z"),
                        hidden: true,
                        hiddenReference: "hidden_ref",
                        mutedStatus: 0,
                        mutedReference: date(from: "2024-06-04T15:03:07.598Z")
                    )
                ),
                name: "Foo Bar",
                messageTimer: 123456,
                readReceiptMode: 1,
                access: [.invite],
                accessRoles: [.teamMember],
                legacyAccessRole: .nonActivated,
                lastEvent: "lastEvent",
                lastEventTime: date(from: "1970-01-01T00:00:00.000Z")
            )
        )

        static let deleteEvent = ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: date(from: "2024-06-04T15:03:07.598Z")
        )

        static let memberJoinEvent = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: date(from: "2024-06-04T15:03:07.598Z"),
            members: [
                Conversation.Member(
                    qualifiedID: QualifiedID(
                        uuid: UUID(uuidString: "2accd221-c35e-4806-a3dd-30718cff5230")!,
                        domain: "example.com"
                    ),
                    id: UUID(uuidString: "2accd221-c35e-4806-a3dd-30718cff5230")!,
                    qualifiedTarget: nil,
                    target: nil,
                    conversationRole: "member",
                    service: nil,
                    archived: nil,
                    archivedReference: nil,
                    hidden: nil,
                    hiddenReference: nil,
                    mutedStatus: nil,
                    mutedReference: nil
                )
            ]
        )

    }

}
