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

import Foundation
import WireDataModelSupport

extension ZMConversationTests {

    func testMigrateMessages_OlderDatesAreDiscarded() throws {
        // GIVEN
        let oldestDate1 = Date()
        let newestDate2 = oldestDate1.addingTimeInterval(60)

        let helper = ModelHelper()
        let user1 = helper.createUser(qualifiedID: .random(), in: uiMOC)
        let conversation1 = helper.createOneOnOne(with: user1, in: uiMOC)

        let messages1Count = 5
        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message1",
            sender: user1,
            count: messages1Count,
            in: uiMOC
        )

        conversation1.previousLastReadServerTimestamp = oldestDate1
        conversation1.lastReadServerTimeStamp = oldestDate1

        let conversation2 = helper.createOneOnOne(with: user1, in: uiMOC)
        conversation2.messageProtocol = .mls

        let messages2Count = 10

        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message2",
            sender: user1,
            count: messages2Count,
            in: uiMOC
        )

        conversation2.pendingLastReadServerTimestamp = newestDate2
        conversation2.previousLastReadServerTimestamp = newestDate2
        conversation2.lastServerTimeStamp = newestDate2
        conversation2.clearedTimeStamp = newestDate2
        conversation2.archivedChangedTimestamp = newestDate2
        conversation2.silencedChangedTimestamp = newestDate2

        // WHEN
        conversation2.migrateMessages(from: conversation1)

        // THEN
        XCTAssertEqual(conversation2.allMessages.count, messages1Count + messages2Count)
        XCTAssertEqual(conversation2.pendingLastReadServerTimestamp, newestDate2)
        XCTAssertEqual(conversation2.previousLastReadServerTimestamp, newestDate2)
        XCTAssertEqual(conversation2.lastServerTimeStamp, newestDate2)
        XCTAssertEqual(conversation2.clearedTimeStamp, newestDate2)
        XCTAssertEqual(conversation2.archivedChangedTimestamp, newestDate2)
        XCTAssertEqual(conversation2.silencedChangedTimestamp, newestDate2)
    }

    func testMigrateMessages_NewerDatesAreApplied() throws {
        // GIVEN
        let newestDate1 = Date()
        let oldestDate2 = newestDate1.addingTimeInterval(-60)
        let messages1Count = 5
        let messages2Count = 10

        let helper = ModelHelper()
        let user1 = helper.createUser(qualifiedID: .random(), in: uiMOC)

        let conversation1 = helper.createOneOnOne(with: user1, in: uiMOC)
        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message1",
            sender: user1,
            count: messages1Count,
            in: uiMOC
        )

        conversation1.pendingLastReadServerTimestamp = newestDate1
        conversation1.previousLastReadServerTimestamp = newestDate1
        conversation1.lastServerTimeStamp = newestDate1
        conversation1.clearedTimeStamp = newestDate1
        conversation1.archivedChangedTimestamp = newestDate1
        conversation1.silencedChangedTimestamp = newestDate1

        let conversation2 = helper.createOneOnOne(with: user1, in: uiMOC)
        conversation2.messageProtocol = .mls
        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message2",
            sender: user1,
            count: messages2Count,
            in: uiMOC
        )

        conversation2.pendingLastReadServerTimestamp = oldestDate2
        conversation2.previousLastReadServerTimestamp = oldestDate2
        conversation2.lastServerTimeStamp = oldestDate2
        conversation2.clearedTimeStamp = oldestDate2
        conversation2.archivedChangedTimestamp = oldestDate2
        conversation2.silencedChangedTimestamp = oldestDate2

        // WHEN
        conversation2.migrateMessages(from: conversation1)

        // THEN
        XCTAssertEqual(conversation2.allMessages.count, messages1Count + messages2Count)
        XCTAssertEqual(conversation2.pendingLastReadServerTimestamp, newestDate1)
        XCTAssertEqual(conversation2.previousLastReadServerTimestamp, newestDate1)
        XCTAssertEqual(conversation2.lastServerTimeStamp, newestDate1)
        XCTAssertEqual(conversation2.clearedTimeStamp, newestDate1)
        XCTAssertEqual(conversation2.archivedChangedTimestamp, newestDate1)
        XCTAssertEqual(conversation2.silencedChangedTimestamp, newestDate1)
    }

    func testMigrateMessages_OtherConversationDatesAreAppliedIfNoDates() throws {
        // GIVEN
        let helper = ModelHelper()
        let user1 = helper.createUser(qualifiedID: .random(), in: uiMOC)
        let conversation1 = helper.createOneOnOne(with: user1, in: uiMOC)
        let date1 = Date()
        let messages1Count = 5
        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message1",
            sender: user1,
            count: messages1Count,
            in: uiMOC
        )

        conversation1.pendingLastReadServerTimestamp = date1
        conversation1.previousLastReadServerTimestamp = date1
        conversation1.lastServerTimeStamp = date1
        conversation1.clearedTimeStamp = date1
        conversation1.archivedChangedTimestamp = date1
        conversation1.silencedChangedTimestamp = date1

        let conversation2 = helper.createOneOnOne(with: user1, in: uiMOC)
        conversation2.messageProtocol = .mls
        let messages2Count = 10
        try helper.addTextMessages(
            to: conversation1,
            messagePrefix: "message2",
            sender: user1,
            count: messages2Count,
            in: uiMOC
        )

        // WHEN
        conversation2.migrateMessages(from: conversation1)

        // THEN
        XCTAssertEqual(conversation2.allMessages.count, messages1Count + messages2Count)
        XCTAssertEqual(conversation2.pendingLastReadServerTimestamp, date1)
        XCTAssertEqual(conversation2.previousLastReadServerTimestamp, date1)
        XCTAssertEqual(conversation2.lastServerTimeStamp, date1)
        XCTAssertEqual(conversation2.clearedTimeStamp, date1)
        XCTAssertEqual(conversation2.archivedChangedTimestamp, date1)
        XCTAssertEqual(conversation2.silencedChangedTimestamp, date1)
    }

    func testThatClearingMessageHistorySetsLastReadServerTimeStampToLastServerTimeStamp() {
        // given
        let clearedTimeStamp = Date()

        let otherUser = createUser()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = clearedTimeStamp

        let message1 = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: uiMOC)
        message1.serverTimestamp = clearedTimeStamp
        message1.sender = otherUser
        message1.visibleInConversation = conversation

        XCTAssertNil(conversation.lastReadServerTimeStamp)

        // when
        conversation.clearMessageHistory()
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertEqual(conversation.lastReadServerTimeStamp, clearedTimeStamp)
    }

    // MARK: - SendOnlyEncryptedMessages

    func testThatItInsertsEncryptedKnockMessages() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        try! conversation.appendKnock()

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = try uiMOC.fetch(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first is ZMClientMessage)
    }

    func testThatItInsertsEncryptedTextMessages() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        conversation._appendText(content: "hello")

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = try uiMOC.fetch(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first is ZMClientMessage)
    }

    func testThatItInsertsEncryptedImageMessages() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        try conversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()),
            nonce: UUID()
        )

        // then
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        let result = try uiMOC.fetch(request)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first is ZMAssetClientMessage)
    }

    // MARK: - Domain tests

    func testThatItTreatsEmptyDomainAsNil() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedAndWait {
            // when
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: "", in: self.syncMOC)

            // then
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItIgnoresDomainWhenFederationIsDisabled() {
        // given
        let uuid = UUID.create()

        syncMOC.performGroupedAndWait {
            // when
            self.syncMOC.isFederationEnabled = false
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: "a.com", in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(nil, created.domain)
        }
    }

    func testThatItAssignsDomainWhenFederationIsEnabled() {
        // given
        let uuid = UUID.create()
        let domain = "a.com"

        syncMOC.performGroupedAndWait {
            // when
            self.syncMOC.isFederationEnabled = true
            let created = ZMConversation.fetchOrCreate(with: uuid, domain: domain, in: self.syncMOC)

            // then
            XCTAssertNotNil(created)
            XCTAssertEqual(uuid, created.remoteIdentifier)
            XCTAssertEqual(domain, created.domain)

            // Since the test class is an objc class, we can't set this to false in tearDown because APIVersion is a
            // swift enum
            self.syncMOC.isFederationEnabled = false
        }
    }

    // MARK: - Appending image messages

    func testThatAppendingAnImageMessageInAnArchivedConversationUnarchivesIt() throws {
        try assertThatAppendingAMessageUnarchivesAConversation { conversation  in
            try conversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()),
                nonce: UUID()
            )
        }
    }

    private func assertThatAppendingAMessageUnarchivesAConversation(
        insertBlock: (ZMConversation) throws
            -> Void
    ) throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        conversation.isArchived = true
        XCTAssertTrue(conversation.isArchived)

        // when
        try insertBlock(conversation)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(conversation.isArchived)
    }

}

// MARK: - Helper Extension

extension ZMConversationTestsBase {
    @discardableResult
    @objc(insertConversationWithUnread:context:)
    func insertConversation(withUnread hasUnread: Bool, context: NSManagedObjectContext) -> ZMConversation {
        let messageDate = Date(timeIntervalSince1970: 230_000_000)
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.conversationType = .oneOnOne
        conversation.lastServerTimeStamp = messageDate
        if hasUnread {
            let message = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: context)
            message.serverTimestamp = messageDate
            conversation.lastReadServerTimeStamp = messageDate.addingTimeInterval(-1000)
            conversation.append(message)
        }
        context.saveOrRollback()
        return conversation
    }
}
