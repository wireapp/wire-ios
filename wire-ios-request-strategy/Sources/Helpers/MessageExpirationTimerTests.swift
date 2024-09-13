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

import WireDataModel
import WireRequestStrategy
import WireTesting
import XCTest

final class MessageExpirationTimerTests: MessagingTestBase {
    var sut: MessageExpirationTimer!
    var localNotificationDispatcher: MockPushMessageHandler!

    override func setUp() {
        super.setUp()
        localNotificationDispatcher = MockPushMessageHandler()
        sut = MessageExpirationTimer(
            moc: uiMOC,
            entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()],
            localNotificationDispatcher: localNotificationDispatcher
        )
    }

    override func tearDown() {
        sut.tearDown()
        sut = nil
        localNotificationDispatcher = nil
        super.tearDown()
    }
}

extension MessageExpirationTimerTests {
    func testThatItExpireAMessageImmediately() {
        // GIVEN
        let message = clientMessage(expirationTime: -2)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        sut.objectsDidChange(messageSet)

        // THEN
        checkExpiration(of: message)
    }

    func testThatItExpiresAMessageWhenItsTimeRunsOut() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        sut.objectsDidChange(messageSet)
        wait(forConditionToBeTrue: message.isExpired, timeout: 2)

        // THEN
        checkExpiration(of: message)
    }

    func testThatItNotifiesTheLocalNotificaitonDispatcherWhenItsTimeRunsOut() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        sut.objectsDidChange(messageSet)
        wait(forConditionToBeTrue: message.isExpired, timeout: 2)

        // THEN
        XCTAssertEqual(localNotificationDispatcher.failedToSend, [message])
    }

    func testThatItDoesNotExpireAMessageWhenDeliveredIsSetToTrue() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.delivered = true

        // WHEN
        sut.objectsDidChange(messageSet)
        spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertFalse(message.isExpired)
    }

    func testThatItExpiresAMessageWhenDeliveredIsNotTrue() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.delivered = false

        // WHEN
        sut.objectsDidChange(messageSet)
        spinMainQueue(withTimeout: 0.4)

        // THEN
        checkExpiration(of: message)
    }

    func testThatItDoesNotExpireAMessageForWhichTheTimerWasStopped() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.2)
        let messageSet: Set<NSManagedObject> = [message]
        sut.objectsDidChange(messageSet)

        // WHEN
        sut.stop(for: message)
        spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertNotNil(message.expirationDate)
        XCTAssertFalse(message.isExpired)
    }

    func testThatItDoesNotExpireAMessageThatHasNoExpirationDate() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)
        let messageSet: Set<NSManagedObject> = [message]
        message.removeExpirationDate()

        // WHEN
        sut.objectsDidChange(messageSet)
        spinMainQueue(withTimeout: 0.4)

        // THEN
        XCTAssertNil(message.expirationDate)
        XCTAssertFalse(message.isExpired)
    }

    func testThatItStartsTimerForStoredMessagesOnFirstRequest() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.1)

        // WHEN
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers([sut!], on: uiMOC)
        wait(forConditionToBeTrue: message.isExpired, timeout: 2)

        // THEN
        checkExpiration(of: message)
    }

    func testThatItDoesNotHaveMessageTimersRunningWhenThereIsNoMessage() {
        XCTAssertFalse(sut.hasMessageTimersRunning)
    }

    func testThatItDoesNotHaveMessageTimersRunningWhenThereIsNoMessageBecauseTheyAreExpired() {
        // GIVEN
        let message = clientMessage(expirationTime: -2)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        sut.objectsDidChange(messageSet)
        wait(forConditionToBeTrue: message.isExpired, timeout: 2)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertFalse(sut.hasMessageTimersRunning)
    }

    func testThatItHasMessageTimersRunningWhenThereIsAMessage() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.5)
        let messageSet: Set<NSManagedObject> = [message]

        // WHEN
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(sut.hasMessageTimersRunning)
        wait(forConditionToBeTrue: message.isExpired, timeout: 2)
    }
}

// MARK: - Slow sync

extension MessageExpirationTimerTests {
    func testThatItReturnsCorrectFetchRequest() {
        // WHEN
        let request = sut.fetchRequestForTrackedObjects()

        // THEN
        let expected = ZMMessage.sortedFetchRequest(with: ZMMessage.predicateForMessagesThatWillExpire())
        XCTAssertEqual(request, expected)
    }

    func testThatItAddsObjectsThatNeedProcessing() {
        // GIVEN
        let message = clientMessage(expirationTime: 0.4)
        let anotherMessage = clientMessage(expirationTime: 0.4)

        XCTAssertFalse(sut.hasMessageTimersRunning)

        // WHEN
        let messageAndAnotherMessageSet: Set<NSManagedObject> = [message, anotherMessage]
        sut.addTrackedObjects(messageAndAnotherMessageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(sut.hasMessageTimersRunning)
        XCTAssertEqual(sut.runningTimersCount, 2)
    }
}

// MARK: - Helpers

extension MessageExpirationTimerTests {
    /// Creates a message with expiration time
    private func clientMessage(expirationTime: TimeInterval) -> ZMClientMessage {
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        ZMMessage.setDefaultExpirationTime(expirationTime)
        message.setExpirationDate()
        XCTAssertTrue(uiMOC.saveOrRollback())
        ZMMessage.resetDefaultExpirationTime()
        return message
    }

    /// Checks that the message is expired. Asserts if not.
    private func checkExpiration(of message: ZMMessage, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        XCTAssertFalse(message.hasChanges, file: file, line: line)
        XCTAssertNil(message.expirationDate, file: file, line: line)
        XCTAssertTrue(message.isExpired, file: file, line: line)
    }
}
