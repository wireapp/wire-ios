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

    func testThatItUpdatesUsersMissingMetadata() {
        // given
        let otherUser = createUserIsPendingMetadataRefresh(moc: syncMOC, domain: UUID().uuidString)
        syncMOC.saveOrRollback()

        let recurringActionService = RecurringActionService()
        sut.recurringActionService = recurringActionService

        recurringActionService.persistLastCheckDate(for: "refreshUserMetadata")
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
        let conversation = createConversationIsPendingMetadataRefresh(moc: syncMOC, domain: UUID().uuidString)
        syncMOC.saveOrRollback()

        let recurringActionService = RecurringActionService()
        sut.recurringActionService = recurringActionService

        recurringActionService.persistLastCheckDate(for: "refreshConversationMetadata")
        recurringActionService.registerAction(sut.refreshConversationsMissingMetadata(interval: 1))

        // when
        XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
        Thread.sleep(forTimeInterval: 3)
        recurringActionService.performActionsIfNeeded()

        // then
        XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
    }

    private func createUserIsPendingMetadataRefresh(moc: NSManagedObjectContext, domain: String?) -> ZMUser {
        let user = ZMUser(context: moc)
        user.remoteIdentifier = UUID()
        user.domain = domain
        user.needsToBeUpdatedFromBackend = false
        user.isPendingMetadataRefresh = true

        return user

    }

    private func createConversationIsPendingMetadataRefresh(moc: NSManagedObjectContext, domain: String?) -> ZMConversation {
        let conversation = ZMConversation(context: moc)
        conversation.remoteIdentifier = UUID()
        conversation.domain = domain
        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = true

        return conversation

    }

}
