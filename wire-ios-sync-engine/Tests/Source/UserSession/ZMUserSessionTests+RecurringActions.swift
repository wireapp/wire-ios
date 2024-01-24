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
import WireTesting
import XCTest

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ZMUserSessionTests_RecurringActions: ZMUserSessionTestsBase {

    var mockRecurringActionService: MockRecurringActionServiceInterface!

    override func setUp() {
        super.setUp()

        mockRecurringActionService = .init()
    }

    override func tearDown() {
        mockRecurringActionService = nil

        super.tearDown()
    }

    func testThatItCallsPerformActionsAfterQuickSync() {
        // Given
        mockRecurringActionService.performActionsIfNeeded_MockMethod = {}
        sut.recurringActionService = mockRecurringActionService

        // When
        XCTAssertTrue(mockRecurringActionService.performActionsIfNeeded_Invocations.isEmpty)
        sut.didFinishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertFalse(mockRecurringActionService.performActionsIfNeeded_Invocations.isEmpty)
    }

    func testUpdatesUsersMissingMetadataAction() {
        syncMOC.performAndWait {
            // Given
            let otherUser = createUserIsPendingMetadataRefresh(moc: syncMOC, domain: UUID().uuidString)
            syncMOC.saveOrRollback()
            let action = sut.refreshUsersMissingMetadataAction

            // When
            action()
            syncMOC.refreshAllObjects()

            // Then
            XCTAssertEqual(action.interval, 3 * .oneHour)
            XCTAssertTrue(otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItUpdatesConversationsMissingMetadata() {
        syncMOC.performAndWait {
            // Given
            let conversation = createConversationIsPendingMetadataRefresh(moc: syncMOC, domain: UUID().uuidString)
            syncMOC.saveOrRollback()
            let action = sut.refreshConversationsMissingMetadataAction

            // When
            action()
            syncMOC.refreshAllObjects()

            // Then
            XCTAssertEqual(action.interval, 3 * .oneHour)
            XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Helpers

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
