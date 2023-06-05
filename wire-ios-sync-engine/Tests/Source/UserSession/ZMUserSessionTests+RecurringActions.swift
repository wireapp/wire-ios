//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import XCTest
@testable import WireSyncEngine

class ZMUserSessionTests_RecurringActions: ZMUserSessionTestsBase {

    var mockRecurringActionService: MockRecurringActionService!

    override func setUp() {
        super.setUp()

        mockRecurringActionService = MockRecurringActionService()
    }

    override func tearDown() {
        mockRecurringActionService = nil

        super.tearDown()
    }

    func testThatItCallsPerformActionsAfterQuickSync() {
        // given
        sut.recurringActionService = mockRecurringActionService

        // when
        XCTAssertFalse(mockRecurringActionService.performActionsIsCalled)
        sut.didFinishQuickSync()

        // then
        XCTAssertTrue(mockRecurringActionService.performActionsIsCalled)
    }

    func testThatItAddsActions() {
        // given
        let action = RecurringAction(id: "11", interval: 5, perform: {})
        sut.recurringActionService = mockRecurringActionService

        // when
        XCTAssertEqual(mockRecurringActionService.actions.count, 0)
        sut.recurringActionService.registerAction(action)

        // then
        XCTAssertEqual(mockRecurringActionService.actions.count, 1)
    }

    func testThatItUpdatesUsersMissingMetadata() {
        // given
        let otherUser = createUser(moc: syncMOC, domain: UUID().uuidString)
        syncMOC.saveOrRollback()

        let recurringActionService = RecurringActionService()
        sut.recurringActionService = recurringActionService

        recurringActionService.persistLastActionDate(for: "refreshUserMetadata")
        recurringActionService.registerAction(sut.refreshUsersMissingMetadata(interval: 1))

        // when
        XCTAssertFalse(otherUser.needsToBeUpdatedFromBackend)
        Thread.sleep(forTimeInterval: 3)
        recurringActionService.performActionsIfNeeded()

        // then
        XCTAssertTrue(otherUser.needsToBeUpdatedFromBackend)
    }

    func testThatItUpdatesConversationsMissingMetadata() {
        // given
        let conversation = createConversation(moc: syncMOC, domain: UUID().uuidString)
        syncMOC.saveOrRollback()

        let recurringActionService = RecurringActionService()
        sut.recurringActionService = recurringActionService

        recurringActionService.persistLastActionDate(for: "refreshConversationMetadata")
        recurringActionService.registerAction(sut.refreshConversationsMissingMetadata(interval: 1))

        // when
        XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
        Thread.sleep(forTimeInterval: 3)
        recurringActionService.performActionsIfNeeded()

        // then
        XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
    }

    private func createUser(moc: NSManagedObjectContext, domain: String?) -> ZMUser {
        let user = ZMUser(context: moc)
        user.remoteIdentifier = UUID()
        user.domain = domain
        user.needsToBeUpdatedFromBackend = false
        user.isPendingMetadataRefresh = true

        return user

    }

    private func createConversation(moc: NSManagedObjectContext, domain: String?) -> ZMConversation {
        let conversation = ZMConversation(context: moc)
        conversation.remoteIdentifier = UUID()
        conversation.domain = domain
        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = true

        return conversation

    }

}
