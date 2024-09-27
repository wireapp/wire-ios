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
            for contextChangeTracker in self.sut.contextChangeTrackers {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                contextChangeTracker.objectsDidChange(otherClientSet)
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
            for contextChangeTracker in self.sut.contextChangeTrackers {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                contextChangeTracker.objectsDidChange(otherClientSet)
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }
}
