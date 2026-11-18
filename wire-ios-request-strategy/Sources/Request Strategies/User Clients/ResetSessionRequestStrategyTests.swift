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

import WireRequestStrategySupport
import XCTest

@testable import WireRequestStrategy

class ResetSessionRequestStrategyTests: MessagingTestBase {

    var sut: ResetSessionRequestStrategy!
    var mockMessageSender: MockMessageSenderInterface!

    override var useInMemoryStore: Bool {
        false
    }

    override func setUp() {
        super.setUp()
        mockMessageSender = MockMessageSenderInterface()
        sut = ResetSessionRequestStrategy(
            managedObjectContext: syncMOC,
            messageSender: mockMessageSender
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatItSendsSessionResetMessage_WhenUserClientNeedsToNotifyOtherUserAboutSessionReset() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = self.createUser()
            let otherClient = self.createClient(user: otherUser)
            _ = self.setupOneToOneConversation(with: otherUser)
            otherClient.needsToNotifyOtherUserAboutSessionReset = true
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                $0.objectsDidChange(otherClientSet)
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    // MARK: Response handling

    func testThatItResetsNeedsToNotifyOtherUserAboutSessionReset_WhenReceivingTheResponse() {
        var otherClient: UserClient!
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = self.createUser()
            _ = self.setupOneToOneConversation(with: otherUser)
            otherClient = self.createClient(user: otherUser)
            otherClient.needsToNotifyOtherUserAboutSessionReset = true
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                $0.objectsDidChange(otherClientSet)
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

    // MARK: Rebuilding the session over Proteus

    func testThatItRebuildsTheSessionAndTargetsOnlyTheClient_WhenAProteusConversationIsShared() throws {
        // GIVEN
        let mockSessionEstablisher = MockSessionEstablisherInterface()
        mockSessionEstablisher.establishSessionWithApiVersion_MockMethod = { _, _ in }
        mockMessageSender.sendMessageMessage_MockMethod = { _ in }
        sut = ResetSessionRequestStrategy(
            managedObjectContext: syncMOC,
            messageSender: mockMessageSender,
            sessionEstablisher: mockSessionEstablisher,
            apiVersion: .v5
        )

        var otherClient: UserClient!
        var groupConversation: ZMConversation!
        var expectedClientID: QualifiedClientID?
        syncMOC.performGroupedAndWait {
            let otherUser = self.createUser()
            otherClient = self.createClient(user: otherUser)
            groupConversation = self.createGroupConversation(with: otherUser)
            expectedClientID = otherClient.qualifiedClientID
            otherClient.needsToNotifyOtherUserAboutSessionReset = true

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange([otherClient])
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        let establishedClients = mockSessionEstablisher.establishSessionWithApiVersion_Invocations.first?.clients
        XCTAssertEqual(establishedClients, expectedClientID.map { [$0] })

        let message = try XCTUnwrap(
            mockMessageSender.sendMessageMessage_Invocations.first as? GenericMessageEntity
        )
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message.conversation, groupConversation)
            guard case let .clients(clientsByUser) = message.targetRecipients else {
                return XCTFail("Expected the message to target specific clients")
            }
            XCTAssertEqual(Array(clientsByUser.values), [[otherClient]])
            XCTAssertFalse(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

    func testThatItFallsBackToTheOneToOneConversation_WhenNoProteusConversationIsShared() throws {
        // GIVEN
        let mockSessionEstablisher = MockSessionEstablisherInterface()
        mockMessageSender.sendMessageMessage_MockMethod = { _ in }
        sut = ResetSessionRequestStrategy(
            managedObjectContext: syncMOC,
            messageSender: mockMessageSender,
            sessionEstablisher: mockSessionEstablisher,
            apiVersion: .v5
        )

        var oneToOneConversation: ZMConversation!
        syncMOC.performGroupedAndWait {
            let otherUser = self.createUser()
            let otherClient = self.createClient(user: otherUser)
            oneToOneConversation = self.setupOneToOneConversation(with: otherUser)
            oneToOneConversation.messageProtocol = .mls
            otherClient.needsToNotifyOtherUserAboutSessionReset = true

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange([otherClient])
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(mockSessionEstablisher.establishSessionWithApiVersion_Invocations.isEmpty)
        let message = try XCTUnwrap(
            mockMessageSender.sendMessageMessage_Invocations.first as? GenericMessageEntity
        )
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message.conversation, oneToOneConversation)
        }
    }

    func testThatItDoesNotSendAndClearsTheFlag_WhenEstablishingTheSessionFails() {
        // GIVEN
        struct EstablishError: Error {}
        let mockSessionEstablisher = MockSessionEstablisherInterface()
        mockSessionEstablisher.establishSessionWithApiVersion_MockError = EstablishError()
        mockMessageSender.sendMessageMessage_MockMethod = { _ in }
        sut = ResetSessionRequestStrategy(
            managedObjectContext: syncMOC,
            messageSender: mockMessageSender,
            sessionEstablisher: mockSessionEstablisher,
            apiVersion: .v5
        )

        var otherClient: UserClient!
        syncMOC.performGroupedAndWait {
            let otherUser = self.createUser()
            otherClient = self.createClient(user: otherUser)
            _ = self.createGroupConversation(with: otherUser)
            otherClient.needsToNotifyOtherUserAboutSessionReset = true

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange([otherClient])
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

}
