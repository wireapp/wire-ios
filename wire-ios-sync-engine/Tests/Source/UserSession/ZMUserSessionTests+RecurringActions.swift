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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ZMUserSessionTests_RecurringActions: ZMUserSessionTestsBase {

    // The mock in this place is a workaround, because somewhere down the line the test funcs call
    // `func handle(...)` and this calls `sut.didFinishQuickSync()` and this calls `PushSupportedProtocolsAction`.
    // A proper solution and mocking requires a further refactoring.
    private var mockPushSupportedProtocolsActionHandler: MockActionHandler<PushSupportedProtocolsAction>!

    override func setUp() {
        super.setUp()
        mockPushSupportedProtocolsActionHandler = .init(
            result: .success(()),
            context: syncMOC.notificationContext
        )
    }

    override func tearDown() {
        mockPushSupportedProtocolsActionHandler = nil

        super.tearDown()
    }

    func testThatItCallsPerformActionsAfterQuickSync() {
        // Given
        mockRecurringActionService.performActionsIfNeeded_MockMethod = {}

        // When
        XCTAssertTrue(mockRecurringActionService.performActionsIfNeeded_Invocations.isEmpty)
        syncMOC.performAndWait {
            sut.didFinishIncrementalSync(isRecovering: false)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertFalse(mockRecurringActionService.performActionsIfNeeded_Invocations.isEmpty)
    }

    func testUpdatesUsersMissingMetadataAction() async {
        // Given
        let otherUser = await syncMOC.perform {
            let user = self.createUserIsPendingMetadataRefresh(
                moc: self.syncMOC,
                domain: UUID().uuidString
            )
            self.syncMOC.saveOrRollback()
            return user
        }

        let action = sut.refreshUsersMissingMetadataAction

        // When
        await action()

        // Then
        await syncMOC.perform {
            XCTAssertEqual(action.interval, 3 * .oneHour)
            XCTAssertTrue(otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItUpdatesConversationsMissingMetadata() async {
        let conversation = await syncMOC.perform {
            // Given
            let conversation = self.createConversationIsPendingMetadataRefresh(
                moc: self.syncMOC,
                domain: UUID().uuidString
            )
            self.syncMOC.saveOrRollback()
            return conversation
        }

        let action = sut.refreshConversationsMissingMetadataAction

        // When
        await action()

        // Then
        await syncMOC.perform {
            XCTAssertEqual(action.interval, 3 * .oneHour)
            XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
        }
    }

    func testTeamMetadataIsUpdated() async {
        // Given
        let membership = await syncMOC.perform {
            let membership = Member.insertNewObject(in: self.syncMOC)
            membership.user = .selfUser(in: self.syncMOC)
            membership.team = .init(context: self.syncMOC)
            membership.user?.teamIdentifier = membership.team?.remoteIdentifier
            self.syncMOC.saveOrRollback()
            return membership
        }

        let action = sut.refreshTeamMetadataAction

        // When
        await action()

        // Then
        await syncMOC.perform {
            XCTAssertEqual(action.interval, .oneDay)
            XCTAssertEqual(membership.team?.needsToBeUpdatedFromBackend, true)
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

    private func createConversationIsPendingMetadataRefresh(
        moc: NSManagedObjectContext,
        domain: String?
    ) -> ZMConversation {
        let conversation = ZMConversation(context: moc)
        conversation.remoteIdentifier = UUID()
        conversation.domain = domain
        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = true
        return conversation
    }
}
