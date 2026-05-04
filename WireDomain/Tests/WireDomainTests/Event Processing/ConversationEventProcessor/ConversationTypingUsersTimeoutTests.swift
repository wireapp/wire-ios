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

import WireDataModel
import WireDataModelSupport
import XCTest
@testable import WireDomain

final class ConversationTypingUsersTimeoutTests: XCTestCase {

    private var sut: ConversationTypingUsersTimeout!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    private var conversationAObjectID: NSManagedObjectID!
    private var conversationBObjectID: NSManagedObjectID!
    private var userAObjectID: NSManagedObjectID!
    private var userBObjectID: NSManagedObjectID!

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        sut = ConversationTypingUsersTimeout()

        await setupObjectIDs()
    }

    override func tearDown() async throws {
        sut = nil
        modelHelper = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        conversationAObjectID = nil
        conversationBObjectID = nil
        userAObjectID = nil
        userBObjectID = nil
    }

    // MARK: - Adding / Removing Users

    func testContains_It_Does_Not_Contain_Users_That_We_Have_Not_Added() {

        // Given, then

        XCTAssertFalse(sut.contains(userAObjectID, for: conversationAObjectID))
        XCTAssertFalse(sut.contains(userBObjectID, for: conversationBObjectID))
    }

    func testContains_It_Can_Add_A_User() {

        // When

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: Date())

        // Then

        XCTAssertTrue(sut.contains(userAObjectID, for: conversationAObjectID))
    }

    func testRemove_It_Can_Remove_A_User() {

        // Given

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: Date())
        sut.add(userBObjectID, for: conversationAObjectID, withTimeout: Date())

        // When

        sut.remove(userAObjectID, for: conversationAObjectID)

        // Then

        XCTAssertFalse(sut.contains(userAObjectID, for: conversationAObjectID))
        XCTAssertTrue(sut.contains(userBObjectID, for: conversationAObjectID))
    }

    func test_That_First_Timeout_Is_Nil_If_Timeouts_Is_Empty() {

        // Given, Then

        XCTAssertNil(sut.firstTimeout)
    }

    func testRemove_First_Timeout_Is_Nil_For_Users_Added_And_Removed_Again() {

        // Given

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: Date())

        // When

        sut.remove(userAObjectID, for: conversationAObjectID)

        // Then

        XCTAssertNil(sut.firstTimeout)
    }

    func testThatItReturnsTheTimeoutWhenAUserIsAdded() {
        // Given
        let timeout = Date()

        // When
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout)

        // Then
        XCTAssertEqual(sut.firstTimeout, timeout)
    }

    func testAdd_It_Returns_The_Earliest_Timeout_When_Multiple_Are_Added() {

        // Given

        let timeout1 = Date()
        let timeout2 = timeout1.addingTimeInterval(10)
        let timeout3 = timeout2.addingTimeInterval(20)

        // When

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout1)
        sut.add(userAObjectID, for: conversationBObjectID, withTimeout: timeout2)
        sut.add(userBObjectID, for: conversationAObjectID, withTimeout: timeout3)

        // Then

        XCTAssertEqual(sut.firstTimeout, timeout1)
    }

    func testAdd_It_Returns_The_Last_Set_Timeout_When_Added_Multiple_Times_For_The_Same_User_And_Conversation() {

        // Given

        let timeout1 = Date()
        let timeout2 = timeout1.addingTimeInterval(10)
        let timeout3 = timeout2.addingTimeInterval(20)

        // When

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout1)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout2)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout3)

        // Then

        XCTAssertEqual(sut.firstTimeout, timeout3)
    }

    func testAdd_It_Returns_The_Currently_Typing_User_Ids() {

        // Given

        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: Date())
        sut.add(userBObjectID, for: conversationAObjectID, withTimeout: Date())

        // When

        let result = sut.userIds(in: conversationAObjectID)

        // Then

        XCTAssertEqual(result, Set([userAObjectID, userBObjectID]))
    }

    func testUserIds_It_Returns_An_Empty_Set_When_No_Users_Are_Typing() {

        // When

        let result = sut.userIds(in: conversationAObjectID)

        // Then

        XCTAssertEqual(result, Set())
    }

    func testPruneConversations_It_Returns_An_Empty_Set_When_Pruning_And_Nothing_Was_Added() {
        // When
        let result = sut.pruneConversationsThatHaveTimoutBefore(date: Date(timeIntervalSinceNow: -10))

        // Then
        XCTAssertEqual(result, Set())
    }

    func testPruneConversations_It_Returns_An_Empty_Set_When_Pruning_And_Nothing_Has_Expired() {

        // Given

        let timeout = Date(timeIntervalSinceNow: 10)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout)

        // When

        let result = sut.pruneConversationsThatHaveTimoutBefore(date: Date())

        // Then

        XCTAssertEqual(result, Set())
    }

    func testPruneConversationsIt_Returns_A_Pruned_Conversation() {

        // Given

        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 20)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout1)

        // When

        let result = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then

        XCTAssertEqual(result, Set([conversationAObjectID]))
    }

    func testPruneConversations_It_Returns_Multiple_Pruned_Conversations() {

        // Given

        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 20)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout1)
        sut.add(userBObjectID, for: conversationBObjectID, withTimeout: timeout1)

        // When

        let result = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then

        XCTAssertEqual(result, Set([conversationAObjectID, conversationBObjectID]))
    }

    func testPruneConversations_It_Removes_Users_When_Pruning() {

        // Given

        let timeout1 = Date(timeIntervalSinceNow: 10)
        let timeout2 = Date(timeIntervalSinceNow: 15)
        let timeout3 = Date(timeIntervalSinceNow: 20)
        sut.add(userAObjectID, for: conversationAObjectID, withTimeout: timeout1)
        sut.add(userBObjectID, for: conversationAObjectID, withTimeout: timeout3)

        // When

        _ = sut.pruneConversationsThatHaveTimoutBefore(date: timeout2)

        // Then

        XCTAssertFalse(sut.contains(userAObjectID, for: conversationAObjectID))
        XCTAssertTrue(sut.contains(userBObjectID, for: conversationAObjectID))
        XCTAssertEqual(sut.userIds(in: conversationAObjectID), Set([userBObjectID]))
    }

    private func setupObjectIDs() async {
        await context.perform { [self] in
            conversationAObjectID = modelHelper.createGroupConversation(
                in: context
            ).objectID

            conversationBObjectID = modelHelper.createGroupConversation(
                in: context
            ).objectID

            userAObjectID = modelHelper.createUser(
                in: context
            ).objectID

            userBObjectID = modelHelper.createUser(
                in: context
            ).objectID
        }
    }
}
