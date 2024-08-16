//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import XCTest

@testable import WireRequestStrategy
@testable import WireRequestStrategySupport

class LinkPreviewUpdateRequestStrategyTests: MessagingTestBase {

    private var sut: LinkPreviewUpdateRequestStrategy!
    private var mockMessageSender: MockMessageSenderInterface!
    private var applicationStatus: MockApplicationStatus!

    private var apiVersion: APIVersion! {
        didSet {
            setCurrentAPIVersion(apiVersion)
        }
    }

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedAndWait { syncMOC in
            self.groupConversation.domain = "example.com"
            self.applicationStatus = MockApplicationStatus()
            self.mockMessageSender = MockMessageSenderInterface()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = LinkPreviewUpdateRequestStrategy(
                managedObjectContext: syncMOC,
                messageSender: self.mockMessageSender
            )
        }

        apiVersion = .v0
    }

    override func tearDown() {
        applicationStatus = nil
        sut = nil
        apiVersion = nil
        super.tearDown()
    }

    func testThatItDoesNotCreateARequestInState_Done() {
        self.verifyThatItDoesNotScheduleMessageUpdate(for: .done)
    }

    func testThatItDoesNotCreateARequestInState_WaitingToBeProcessed() {
        self.verifyThatItDoesNotScheduleMessageUpdate(for: .waitingToBeProcessed)
    }

    func testThatItDoesNotCreateARequestInState_Downloaded() {
        self.verifyThatItDoesNotScheduleMessageUpdate(for: .downloaded)
    }

    func testThatItDoesNotCreateARequestInState_Processed() {
        self.verifyThatItDoesNotScheduleMessageUpdate(for: .processed)
    }

    func testThatItDoesNotScheduleMessageInState_Uploaded_ForOtherUser() {
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let message = self.insertMessage(with: .uploaded)
            message.sender = self.otherUser

            // When
            self.process(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItDoesCreateARequestInState_Uploaded() {
        apiVersion = .v1

        var message: ZMClientMessage!

        self.syncMOC.performGroupedAndWait { _ in
            // Given
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            message = self.insertMessage(with: .uploaded)

            // When
            self.process(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)

        self.syncMOC.performGroupedAndWait { _ in
            XCTAssertEqual(message.linkPreviewState, .done)
            XCTAssertNil(message.expirationDate)
        }
    }

    func testThatItDoesNotCreateARequestAfterGettingsAResponseForIt() {
        apiVersion = .v1
        var message: ZMClientMessage!
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            message = self.insertMessage(with: .uploaded)
            self.process(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedAndWait { _ in
            // When
            self.process(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    // MARK: - Helper

    func insertMessage(with state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) -> ZMClientMessage {
        let message = try! groupConversation.appendText(content: "Test message") as! ZMClientMessage
        message.linkPreviewState = state
        XCTAssert(syncMOC.saveOrRollback(), file: file, line: line)

        return message
    }

    func verifyThatItDoesNotScheduleMessageUpdate(for state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) {
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let message = self.insertMessage(with: state)

            // When
            self.process(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func process(_ message: ZMClientMessage) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange([message])
        }
    }

}
