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
@testable import WireDataModel

// NOTE: Some legacy predicates tests already exist in `ZMConversationTests.m`

class ZMConversationTests_Predicates: ZMConversationTestsBase {

    // MARK: - Helpers

    @discardableResult
    private func appendMessage(to conversation: ZMConversation) -> Date {
        if conversation.lastServerTimeStamp == nil {
            conversation.lastServerTimeStamp = Date()
        }
        let message = ZMMessage(nonce: NSUUID.create(), managedObjectContext: conversation.managedObjectContext!)
        message.serverTimestamp = conversation.lastServerTimeStamp!.addingTimeInterval(5)
        message.visibleInConversation = conversation
        conversation.lastServerTimeStamp = message.serverTimestamp
        return message.serverTimestamp!
    }

    // MARK: - predicateForConversationsIncludingArchived

    func test_itDoesNotFilterOut_Cleared_Archived_Conversations_WithNewMessages() {
        uiMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.conversationType = .group
            let clearedTimestamp = appendMessage(to: conversation)

            conversation.isArchived = true
            conversation.clearedTimeStamp = clearedTimestamp
            appendMessage(to: conversation) // new message after cleared

            // The predicate filters on the persisted `effectiveConversationType`, populated in `-willSave`.
            uiMOC.saveOrRollback()

            // when
            let sut = ConversationPredicateFactory(selfUser: ZMUser.selfUser(in: uiMOC))
                .predicateForConversationsIncludingArchived()

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }

    func test_itFiltersOut_Archived_Cleared_Conversations_WithNoNewMessages() {
        uiMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.conversationType = .group
            let clearedTimestamp = appendMessage(to: conversation)

            conversation.isArchived = true
            conversation.clearedTimeStamp = clearedTimestamp

            // when
            let sut = ConversationPredicateFactory(selfUser: ZMUser.selfUser(in: uiMOC))
                .predicateForConversationsIncludingArchived()

            // then
            XCTAssertFalse(sut.evaluate(with: conversation))
        }
    }

    func test_itDoesNotFilter_Cleared_NotArchived_Conversations() {
        uiMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.conversationType = .group
            let clearedTimestamp = appendMessage(to: conversation)

            conversation.clearedTimeStamp = clearedTimestamp
            conversation.isArchived = false

            // The predicate filters on the persisted `effectiveConversationType`, populated in `-willSave`.
            uiMOC.saveOrRollback()

            // when
            let sut = ConversationPredicateFactory(selfUser: ZMUser.selfUser(in: uiMOC))
                .predicateForConversationsIncludingArchived()

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }

    func test_itReturns_Cleared_Archived_Conversations_WhereSearchMatchesAndSelfIsActiveMember() {
        uiMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.userDefinedName = "lala"
            conversation.conversationType = .group
            let selfUser = ZMUser.selfUser(in: uiMOC)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
            let clearedTimestamp = appendMessage(to: conversation)
            uiMOC.saveOrRollback()

            conversation.isArchived = true
            conversation.clearedTimeStamp = clearedTimestamp
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            // when
            let sut = ZMConversation.predicate(forSearchQuery: "lala", team: nil, moc: uiMOC)

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }

    func test_itDoesNotReturn_Cleared_Archived_Conversations_WhereSelfIsNotActiveMember() {
        uiMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.userDefinedName = "lala"
            conversation.conversationType = .group
            let selfUser = ZMUser.selfUser(in: uiMOC)
            let clearedTimestamp = appendMessage(to: conversation)
            uiMOC.saveOrRollback()

            conversation.isArchived = true
            conversation.clearedTimeStamp = clearedTimestamp
            conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: selfUser)

            // when
            let sut = ZMConversation.predicate(forSearchQuery: "lala", team: nil, moc: uiMOC)

            // then
            XCTAssertFalse(sut.evaluate(with: conversation))
        }
    }

    // MARK: - MLS

    func test_itReturnsMlsConversations_withMlsStatusReady() {
        syncMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.conversationType = .group
            conversation.messageProtocol = .mls
            conversation.mlsStatus = .ready

            // The predicate filters on the persisted `effectiveConversationType`, populated in `-willSave`.
            syncMOC.saveOrRollback()

            // when
            let sut = ConversationPredicateFactory(selfUser: ZMUser.selfUser(in: syncMOC))
                .predicateForConversationsIncludingArchived()

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }

    func test_itReturnsMlsConversations_withMlsStatusNotReady() {
        syncMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.conversationType = .group
            conversation.messageProtocol = .mls
            conversation.mlsStatus = .pendingJoin

            // The predicate filters on the persisted `effectiveConversationType`, populated in `-willSave`.
            syncMOC.saveOrRollback()

            // when
            let sut = ConversationPredicateFactory(selfUser: ZMUser.selfUser(in: syncMOC))
                .predicateForConversationsIncludingArchived()

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }
}
