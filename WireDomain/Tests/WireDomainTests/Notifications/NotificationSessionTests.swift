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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class NotificationSessionTests: XCTestCase {
    private var sut: NotificationSession!
    private var authenticationServiceProvider: MockAuthenticationServiceProvider!
    private var authenticationService: MockAuthenticationServiceProtocol!
    private var authenticatedSession: MockAuthenticatedSessionProtocol!

    override func setUp() async throws {
        authenticationServiceProvider = MockAuthenticationServiceProvider()
        authenticationService = MockAuthenticationServiceProtocol()
        authenticatedSession = MockAuthenticatedSessionProtocol()
    }

    override func tearDown() async throws {
        sut = nil
        authenticationService = nil
        authenticationServiceProvider = nil
        authenticatedSession = nil
    }

    func testNotificationSession_It_Generates_Correct_Notifications_Amount() async throws {

        // Given

        let mockEvents = [
            Scaffolding.mlsMessageUpdateEvent,
            Scaffolding.proteusMessageUpdateEvent
        ]

        authenticatedSession.setup_MockMethod = {}
        authenticatedSession.startSyncNewEventID_MockValue = AsyncStream {
            $0.yield(mockEvents) // First batch of 2 events
            $0.yield(mockEvents) // Second batch of 2 events
            $0.finish()
        }
        authenticationService.authenticated_MockValue = authenticatedSession
        authenticationServiceProvider.authenticationService = authenticationService

        var receivedNotifications = [UNMutableNotificationContent]()

        sut = NotificationSession(
            eventID: .mockID7,
            authenticationServiceProvider: authenticationServiceProvider,
            notificationHandler: { notification in
                receivedNotifications.append(notification)
            }
        )

        // When

        try await sut.start()

        // Then

        XCTAssertEqual(receivedNotifications.count, 4) // 4 notifications (2 batches of 2 events) are generated
    }

    func testNotificationSession_It_Throws_Error_When_Unauthenticated() async throws {

        // Given

        enum MockError: Error {
            case unauthenticated
        }

        authenticationService.authenticated_MockError = MockError.unauthenticated
        authenticationServiceProvider.authenticationService = authenticationService

        sut = NotificationSession(
            eventID: .mockID7,
            authenticationServiceProvider: authenticationServiceProvider,
            notificationHandler: { _ in }
        )

        // Then
        await XCTAssertThrowsErrorAsync(MockError.unauthenticated) {
            // When
            try await self.sut.start()
        }
    }

    func testNotificationSession_It_Throws_Error_When_Authenticated_Session_Setup_Fails() async throws {

        // Given

        enum MockError: Error {
            case setupError
        }

        authenticatedSession.setup_MockError = MockError.setupError
        authenticationService.authenticated_MockValue = authenticatedSession
        authenticationServiceProvider.authenticationService = authenticationService

        sut = NotificationSession(
            eventID: .mockID7,
            authenticationServiceProvider: authenticationServiceProvider,
            notificationHandler: { _ in }
        )

        // Then
        await XCTAssertThrowsErrorAsync(MockError.setupError) {
            // When
            try await self.sut.start()
        }
    }

    func testNotificationSession_It_Throws_Error_When_Pull_Sync_Fails() async throws {

        // Given

        enum MockError: Error {
            case pullSyncFailed
        }

        authenticatedSession.setup_MockMethod = {}
        authenticatedSession.startSyncNewEventID_MockError = MockError.pullSyncFailed
        authenticationService.authenticated_MockValue = authenticatedSession
        authenticationServiceProvider.authenticationService = authenticationService

        sut = NotificationSession(
            eventID: .mockID7,
            authenticationServiceProvider: authenticationServiceProvider,
            notificationHandler: { _ in }
        )

        // Then
        await XCTAssertThrowsErrorAsync(MockError.pullSyncFailed) {
            // When
            try await self.sut.start()
        }
    }

    enum Scaffolding {
        static let updateEventEnvelope = UpdateEventEnvelope(
            id: .mockID1,
            events: [mlsMessageUpdateEvent, proteusMessageUpdateEvent],
            isTransient: false
        )

        static let mlsMessageUpdateEvent: UpdateEvent = .conversation(.mlsMessageAdd(mlsMessageAddEvent))

        static let proteusMessageUpdateEvent: UpdateEvent = .conversation(.proteusMessageAdd(proteusMessageAddEvent))

        static let mlsMessageAddEvent = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(uuid: .mockID1, domain: ""),
            senderID: UserID(uuid: .mockID2, domain: ""),
            subconversation: "subconversation",
            message: "message",
            timestamp: .now
        )
        static let proteusMessageAddEvent = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(uuid: .mockID1, domain: ""),
            senderID: UserID(uuid: .mockID2, domain: ""),
            timestamp: .now,
            message: .init(encryptedMessage: "foo"),
            externalData: .init(encryptedMessage: "bar"),
            messageSenderClientID: "abc123",
            messageRecipientClientID: "def456"
        )
    }
}
