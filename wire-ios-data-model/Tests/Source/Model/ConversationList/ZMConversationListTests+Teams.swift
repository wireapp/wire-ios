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

import Foundation
@testable import WireDataModel

final class ZMConversationListTests_Teams: ZMBaseManagedObjectTest {
    var dispatcher: NotificationDispatcher!
    var team: Team!
    var otherTeam: Team!

    override func setUp() {
        super.setUp()
        team = createTeam()
        otherTeam = createTeam()
        dispatcher = NotificationDispatcher(managedObjectContext: uiMOC)
    }

    override func tearDown() {
        team = nil
        otherTeam = nil
        dispatcher.tearDown()
        dispatcher = nil
        super.tearDown()
    }

    func testThatItDoesNotReturnTheSelfConversation() {
        // given
        let group = ZMConversation.insertNewObject(in: uiMOC)
        group.team = team
        group.conversationType = .group
        let selfConversation = ZMConversation.insertNewObject(in: uiMOC)
        selfConversation.conversationType = .self
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items, [group])
    }

    func testThatItReturnConversationsNotInTheCurrentTeam() {
        // given
        let group = ZMConversation.insertNewObject(in: uiMOC)
        group.team = team
        group.conversationType = .group
        let otherGroup = ZMConversation.insertNewObject(in: uiMOC)
        otherGroup.conversationType = .group
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(Set(sut.items), [group, otherGroup])
    }

    func testThatItReturnsAllConversationsOfATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        let archived1 = createGroupConversation(in: team, archived: true)
        let archived2 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.items.count, 4)
        XCTAssertEqual(Set(sut.items), [conversation1, conversation2, archived1, archived2])
    }

    func testThatItReturnsAllArchivedConversationsOfATeam() {
        // given
        createGroupConversation(in: team)
        createGroupConversation(in: team)
        let archived1 = createGroupConversation(in: team, archived: true)
        let archived2 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.archivedConversations(in: uiMOC)

        // then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(Set(sut.items), [archived1, archived2])
    }

    func testThatItReturnsAllUnarchivedConversationsOfATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        createGroupConversation(in: team, archived: true)
        createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(Set(sut.items), [conversation1, conversation2])
    }

    func testThatItReturnsTeamConversationsSorted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12_345_678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(500)
        let conversation3 = createGroupConversation(in: team)
        conversation3.lastModifiedDate = startDate.addingTimeInterval(-200)
        uiMOC.saveOrRollback()

        // when
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        // then
        XCTAssertEqual(sut.items, [conversation2, conversation1, conversation3])
    }

    func testThatItRecreatesListsAndTokensForTeamConversations() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12_345_678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        uiMOC.saveOrRollback()

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: uiMOC)

        let factory = ConversationPredicateFactory(selfTeam: team)

        // when inserting a new conversation while in the background
        dispatcher.applicationDidEnterBackground()
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.items, [conversation1])
        XCTAssertEqual(observer.notifications.count, 0)

        // when refresing the list
        sut.recreate(
            allConversations: [conversation1, conversation2],
            predicate: factory.predicateForConversationsIncludingArchived()
        )

        // then
        XCTAssertEqual(sut.items, [conversation1, conversation2])

        // when forwarding the accumulated changes
        dispatcher.applicationWillEnterForeground()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then the updated snapshot prevents outdated list change notifications
        XCTAssertEqual(observer.notifications.count, 0)
        XCTAssertEqual(sut.items, [conversation1, conversation2])
    }

    func testThatItUpdatesWhenANewTeamConversationIsInserted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12_345_678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: uiMOC)

        // when inserting a new conversation
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.items, [conversation1, conversation2])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatDoesUpdateWhenAConversationInADifferentTeamIsInserted() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12_345_678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate

        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: uiMOC)

        // when inserting a new conversation
        let conversation2 = createGroupConversation(in: otherTeam)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(-10)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        XCTAssertEqual(sut.items, [conversation1, conversation2])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatItUpdatesWhenNewConversationLastModifiedChangesThroughTheNotificationDispatcher() {
        // given
        let startDate = Date(timeIntervalSinceReferenceDate: 12_345_678)
        let conversation1 = createGroupConversation(in: team)
        conversation1.lastModifiedDate = startDate
        let conversation2 = createGroupConversation(in: team)
        conversation2.lastModifiedDate = startDate.addingTimeInterval(20)
        let conversation3 = createGroupConversation(in: team)
        conversation3.lastModifiedDate = startDate.addingTimeInterval(-20)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        let sut = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        XCTAssertEqual(sut.items.count, 3)
        XCTAssertEqual(sut.items, [conversation2, conversation1, conversation3])
        let observer = ConversationListChangeObserver(conversationList: sut, managedObjectContext: uiMOC)

        // when
        XCTAssert(uiMOC.saveOrRollback())
        conversation3.lastModifiedDate = startDate.addingTimeInterval(30)
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(sut.items.count, 3)
        XCTAssertEqual(sut.items, [conversation3, conversation2, conversation1])
        XCTAssertEqual(observer.notifications.count, 1)
    }

    func testThatItUpdatesWhenNewAConversationIsArchivedInATeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let conversation2 = createGroupConversation(in: team)
        let conversation3 = createGroupConversation(in: team)
        let conversation4 = createGroupConversation(in: team, archived: true)
        uiMOC.saveOrRollback()

        // then
        let unarchivedList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssertEqual(unarchivedList.items.count, 3)
        XCTAssertEqual(Set(unarchivedList.items), [conversation2, conversation1, conversation3])

        let archivedList = ZMConversation.archivedConversations(in: uiMOC)
        XCTAssertEqual(archivedList.items.count, 1)
        XCTAssertEqual(archivedList.items, [conversation4])

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let unarchivedObserver = ConversationListChangeObserver(
            conversationList: unarchivedList,
            managedObjectContext: uiMOC
        )
        let archivedObserver = ConversationListChangeObserver(
            conversationList: archivedList,
            managedObjectContext: uiMOC
        )

        // when
        XCTAssert(uiMOC.saveOrRollback())
        conversation2.isArchived = true
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(unarchivedList.items.count, 2)
        XCTAssertEqual(Set(unarchivedList.items), [conversation3, conversation1])
        XCTAssertEqual(unarchivedObserver.notifications.count, 1)

        XCTAssertEqual(archivedList.items.count, 2)
        XCTAssertEqual(Set(archivedList.items), [conversation4, conversation2])
        XCTAssertEqual(archivedObserver.notifications.count, 1)
    }

    func testThatClearingAConversationInATeamMovesItToClearedListInTheTeam() {
        // given
        let conversation1 = createGroupConversation(in: team)
        let message = try! conversation1.appendText(content: "Text") as! ZMMessage
        message.serverTimestamp = Date()
        uiMOC.saveOrRollback()

        // then
        let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        let archivedList = ZMConversation.archivedConversations(in: uiMOC)
        let clearedList = ZMConversation.clearedConversations(in: uiMOC)

        XCTAssertEqual(activeList.items.count, 1)
        XCTAssertEqual(activeList.items, [conversation1])
        XCTAssertEqual(archivedList.items.count, 0)
        XCTAssertEqual(clearedList.items.count, 0)
        XCTAssert(uiMOC.saveOrRollback())

        // when
        conversation1.clearMessageHistory()
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(activeList.items.count, 0)
        XCTAssertEqual(archivedList.items.count, 0)
        XCTAssertEqual(clearedList.items.count, 1)
        XCTAssertEqual(clearedList.items, [conversation1])
    }

    func testThatItDoesNotReturnAConversationAnymoreOnceItGotUnarchived() {
        // given
        let conversation = createGroupConversation(in: team)
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        // then
        do {
            let archivedList = ZMConversation.archivedConversations(in: uiMOC)
            let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
            XCTAssertEqual(archivedList.items, [conversation])
            XCTAssertEqual(activeList.items.count, 0)
        }

        // when
        conversation.isArchived = false
        XCTAssert(uiMOC.saveOrRollback())

        // then
        do {
            let archivedList = ZMConversation.archivedConversations(in: uiMOC)
            let activeList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
            XCTAssertEqual(activeList.items, [conversation])
            XCTAssertEqual(archivedList.items.count, 0)
        }
    }

    // MARK: - Helper

    private func createTeam() -> Team {
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        return team
    }

    // MARK: - Helper

    @discardableResult
    func createGroupConversation(in team: Team?, archived: Bool = false) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation.remoteIdentifier = .create()
        conversation.team = team
        conversation.isArchived = archived
        conversation.conversationType = .group
        return conversation
    }
}
