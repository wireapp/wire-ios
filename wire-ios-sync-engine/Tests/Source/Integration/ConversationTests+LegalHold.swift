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

@testable import WireSyncEngine
import XCTest

class ConversationTests_LegalHold: ConversationTestsBase {

    override var proteusViaCoreCryptoEnabled: Bool {
        true
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenDiscoveringLegalHoldClientOnSending() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)
        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        // when
        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let secondToLastMessage = conversation?.lastMessages()[1] as? ZMSystemMessage
        XCTAssertEqual(secondToLastMessage?.systemMessageType, .legalHoldEnabled)
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenLegalHoldClientIsReportedAsDeletedOnSending() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)
        var legalHoldClient: MockUserClient!
        mockTransportSession.performRemoteChanges { session in
            legalHoldClient = session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        conversation?.acknowledgePrivacyWarningAndResendMessages()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .enabled)

        mockTransportSession.performRemoteChanges { session in
            session.deleteUserClient(withIdentifier: legalHoldClient.identifier!, for: self.user1)
        }

        // when
        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastMessage = conversation?.lastMessage as? ZMSystemMessage
        XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldDisabled)
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenUserUnderLegalHoldIsJoiningConversation() async throws {
        // given
        XCTAssertTrue(login())

        let (legalHoldUser, groupConversation) = await self.userSession!.managedObjectContext.perform({
            return (
                self.user(for: self.user1),
                self.conversation(for: self.groupConversation)
            )
        })

        guard let legalHoldUser, let groupConversation else {
            XCTFail("expect legalHoldUser and groupConversation")
            return
        }

        let conversationParticipantsService = ConversationParticipantsService(context: userSession!.managedObjectContext)
        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }
        await self.userSession?.managedObjectContext.perform {
            legalHoldUser.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when

        try await conversationParticipantsService.addParticipants([legalHoldUser], to: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        await self.userSession!.managedObjectContext.perform {
            let lastMessage = groupConversation.lastMessage as? ZMSystemMessage
            XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldEnabled)
            XCTAssertEqual(groupConversation.legalHoldStatus, .pendingApproval)
        }
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenUserUnderLegalHoldIsLeavingConversation() async throws {
        // given
        XCTAssertTrue(login())

        let (legalHoldUser, groupConversation) = await self.userSession!.managedObjectContext.perform({
            return (
                self.user(for: self.user1),
                self.conversation(for: self.groupConversation)
            )
        })

        guard let legalHoldUser, let groupConversation else {
            XCTFail("expect legalHoldUser and groupConversation")
            return
        }

        let conversationParticipantsService = ConversationParticipantsService(context: userSession!.managedObjectContext)

        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }
        legalHoldUser.fetchUserClients()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try await conversationParticipantsService.addParticipants([legalHoldUser], to: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        await self.userSession!.managedObjectContext.perform {
            XCTAssertEqual(groupConversation.legalHoldStatus, .pendingApproval)
        }

        // when
        try await conversationParticipantsService.removeParticipant(legalHoldUser, from: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        await self.userSession!.managedObjectContext.perform {
            let lastMessage = groupConversation.lastMessage as? ZMSystemMessage
            XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldDisabled)
            XCTAssertEqual(groupConversation.legalHoldStatus, .disabled)
        }
    }

    // MARK: Legal hold status flag

    func testThatItUpdatesLegalHoldStatus_WhenReceivingLegalHoldStatusFlagEnabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        // when
        mockTransportSession.performRemoteChanges { _ in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.enabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }

        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

    func testThatItUpdatesLegalHoldStatus_WhenReceivingLegalHoldStatusFlagDisabled() {
        // given
        XCTAssertTrue(login())

        let legalHoldUser = self.user(for: user1)!
        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        var legalHoldClient: MockUserClient!
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { session in
            legalHoldClient = session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        legalHoldUser.fetchUserClients()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        // when
        mockTransportSession.performRemoteChanges { session in
            session.deleteUserClient(withIdentifier: legalHoldClient.identifier!, for: self.user1)
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.disabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItRepairsAnIncorrectLegalHoldStatus_AfterReceivingLegalHoldStatusFlagEnabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        mockTransportSession.performRemoteChanges { _ in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.enabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

         // then
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItRepairsAnIncorrectLegalHoldStatus_AfterReceivingLegalHoldStatusFlagDisabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { session in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        userSession?.perform {
            try! conversation!.appendText(content: "This is the best group!")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        // when
        mockTransportSession.performRemoteChanges { _ in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.disabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

}
