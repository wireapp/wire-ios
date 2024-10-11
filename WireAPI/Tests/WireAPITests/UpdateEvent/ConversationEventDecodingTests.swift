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
        decoder = .init()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingConversationAccessUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationAccessUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.accessUpdate(Scaffolding.accessUpdateEvent))
        )
    }

    func testDecodingConversationCodeUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationCodeUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.codeUpdate(Scaffolding.codeUpdateEvent))
        )
    }

    func testDecodingConversationCreateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationCreate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.create(Scaffolding.createEvent))
        )
    }

    func testDecodingConversationDeleteEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationDelete")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.delete(Scaffolding.deleteEvent))
        )
    }

    func testDecodingConversationMemberJoinEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMemberJoin")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.memberJoin(Scaffolding.memberJoinEvent))
        )
    }

    func testDecodingConversationMemberLeaveEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMemberLeave")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.memberLeave(Scaffolding.memberLeaveEvent))
        )
    }

    func testDecodingConversationMemberUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMemberUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.memberUpdate(Scaffolding.memberUpdateEvent))
        )
    }

    func testDecodingConversationMessageTimerUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMessageTimerUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.messageTimerUpdate(Scaffolding.messageTimerUpdateEvent))
        )
    }

    func testDecodingConversationMLSMessageAddEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMLSMessageAdd")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.mlsMessageAdd(Scaffolding.mlsMessageAddEvent))
        )
    }

    func testDecodingConversationMLSWelcomeEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationMLSWelcome")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.mlsWelcome(Scaffolding.mlsWelcomeEvent))
        )
    }

    func testDecodingConversationProteusMessageAddEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationProteusMessageAdd")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.proteusMessageAdd(Scaffolding.proteusMessageAddEvent))
        )
    }

    func testDecodingConversationProtocolUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationProtocolUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.protocolUpdate(Scaffolding.protocolUpdateEvent))
        )
    }

    func testDecodingConversationReceiptModeUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationReceiptModeUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.receiptModeUpdate(Scaffolding.receiptModeUpdateEvent))
        )
    }

    func testDecodingConversationRenameEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationRename")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.rename(Scaffolding.renameEvent))
        )
    }

    func testDecodingConversationTypingEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "ConversationTyping")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.typing(Scaffolding.typingEvent))
        )
    }

    private enum Scaffolding {

        static func fractionalDate(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.internetDateTime.date(from: string)!
        }

        static let conversationID = ConversationID(
            uuid: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
            domain: "example.com"
        )

        static let senderID = UserID(
            uuid: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
            domain: "example.com"
        )

        static let timestamp = fractionalDate(from: "2024-06-04T15:03:07.598Z")

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
            timestamp: timestamp,
            conversation: Conversation(
                id: conversationID.uuid,
                qualifiedID: conversationID,
                teamID: UUID(uuidString: "acfb3399-5be5-4cee-b896-1230576c94a2")!,
                type: .group,
                messageProtocol: .proteus,
                mlsGroupID: "group_id",
                cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                epoch: 123,
                epochTimestamp: date(from: "2024-06-04T15:03:07Z"),
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
                        archivedReference: timestamp,
                        hidden: true,
                        hiddenReference: "hidden_ref",
                        mutedStatus: 0,
                        mutedReference: timestamp
                    )
                ),
                name: "Foo Bar",
                messageTimer: 123_456,
                readReceiptMode: 1,
                access: [.invite],
                accessRoles: [.teamMember],
                legacyAccessRole: .nonActivated,
                lastEvent: "lastEvent",
                lastEventTime: fractionalDate(from: "1970-01-01T00:00:00.000Z")
            )
        )

        static let deleteEvent = ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp
        )

        static let memberJoinEvent = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
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

        static let memberLeaveEvent = ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            removedUserIDs: [senderID],
            reason: .userDeleted
        )

        static let memberUpdateEvent = ConversationMemberUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            memberChange: ConversationMemberChange(
                id: senderID,
                newRoleName: "admin",
                newMuteStatus: 1,
                muteStatusReferenceDate: timestamp,
                newArchivedStatus: true,
                archivedStatusReferenceDate: timestamp
            )
        )

        static let messageTimerUpdateEvent = ConversationMessageTimerUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            newTimer: 123
        )

        static let mlsMessageAddEvent = ConversationMLSMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            subconversation: "subconversation",
            message: "message"
        )

        static let mlsWelcomeEvent = ConversationMLSWelcomeEvent(
            conversationID: conversationID,
            senderID: senderID,
            welcomeMessage: "message"
        )

        static let proteusMessageAddEvent = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            message: .ciphertext("foo"),
            externalData: .ciphertext("bar"),
            messageSenderClientID: "abc123",
            messageRecipientClientID: "def456"
        )

        static let protocolUpdateEvent = ConversationProtocolUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            newProtocol: .mls
        )

        static let receiptModeUpdateEvent = ConversationReceiptModeUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            newReceiptMode: 1
        )

        static let renameEvent = ConversationRenameEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            newName: "foo"
        )

        static let typingEvent = ConversationTypingEvent(
            conversationID: conversationID,
            senderID: senderID,
            isTyping: true
        )

    }

}
