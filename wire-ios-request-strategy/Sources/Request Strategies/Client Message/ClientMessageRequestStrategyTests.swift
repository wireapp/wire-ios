//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import GenericMessageProtocol
import WireTransport
import XCTest

@testable import WireDataModelSupport
@testable import WireRequestStrategy
@testable import WireRequestStrategySupport

class ClientMessageRequestStrategyTests: MessagingTestBase {

    var localNotificationDispatcher: MockPushMessageHandler!
    var sut: ClientMessageRequestStrategy!
    var mockAttachmentsDetector: MockAttachmentDetector!
    var mockMessageSender: MockMessageSenderInterface!
    var apiVersion: APIVersion! {
        didSet {
            BackendInfo.apiVersion = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        syncMOC.performAndWait { [self] in
            localNotificationDispatcher = MockPushMessageHandler()
            mockAttachmentsDetector = MockAttachmentDetector()
            mockMessageSender = MockMessageSenderInterface()
            LinkAttachmentDetectorHelper.setTest_debug_linkAttachmentDetector(mockAttachmentsDetector)
            makeSut()
        }

        apiVersion = .v0

    }

    override func tearDown() {
        localNotificationDispatcher = nil
        mockAttachmentsDetector = nil
        LinkAttachmentDetectorHelper.tearDown()
        sut = nil

        super.tearDown()
    }

    func makeSut(hasMLSClient: Bool = false) {
        if hasMLSClient {
            selfClient?.mlsPublicKeys = .init(ed25519: "key")
            selfClient?.needsToUploadMLSPublicKeys = false
        }

        sut = ClientMessageRequestStrategy(
            context: syncMOC,
            localNotificationDispatcher: localNotificationDispatcher,
            messageSender: mockMessageSender
        )
    }

    /// Makes a conversation secure
    func set(conversation: ZMConversation, securityLevel: ZMConversationSecurityLevel) {
        conversation.setValue(NSNumber(value: securityLevel.rawValue), forKey: #keyPath(ZMConversation.securityLevel))
        if conversation.securityLevel != securityLevel {
            fatalError()
        }
    }

}

// MARK: - Request generation

extension ClientMessageRequestStrategyTests {

    func testThatItDoesSendProteusMessageInVisibleConversation() {

        syncMOC.performGroupedAndWait {

            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            XCTAssertEqual(1, self.mockMessageSender.sendMessageMessage_Invocations.count)
        }
    }

    func testThatItDoesSendProteusMessageInHiddenConversation() {

        syncMOC.performGroupedAndWait {

            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            message.visibleInConversation = nil
            message.hiddenInConversation = groupConversation
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            XCTAssertEqual(1, self.mockMessageSender.sendMessageMessage_Invocations.count)
        }
    }

    func testThatItDoesNotSendMLSMessageWhenMLSFeatureDisabled() {

        syncMOC.performGroupedAndWait {

            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            message.conversation?.messageProtocol = .mls
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            XCTAssertEqual(0, self.mockMessageSender.sendMessageMessage_Invocations.count)
        }
    }

    func testThatItDoesSendMLSMessageWhenMLSFeatureEnabled() {

        syncMOC.performGroupedAndWait {

            // GIVEN

            makeSut(hasMLSClient: true)
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            message.conversation?.messageProtocol = .mls
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            XCTAssertEqual(1, self.mockMessageSender.sendMessageMessage_Invocations.count)
        }
    }

    func testThatItDoesNotSendMessageIfSenderIsNotSelfUser() {

        syncMOC.performGroupedAndWait {

            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            message.sender = self.otherUser
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            // THEN
            XCTAssertEqual(0, self.mockMessageSender.sendMessageMessage_Invocations.count)
        }
    }

    func testThatItNotifiesAttachmentPrepocessorOfChanges() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let text = String(repeating: "Hi", count: 100_000)
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage

            // WHEN
            self.syncMOC.saveOrRollback()
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            // THEN
            XCTAssertEqual(self.mockAttachmentsDetector.downloadCount, 1)
        }
    }

    func testThatItDeletesTheConfirmationMessageWhenSentSuccessfully() {

        // GIVEN
        var confirmationMessage: ZMMessage!
        syncMOC.performGroupedAndWait {

            confirmationMessage = try! self.oneToOneConversation
                .appendClientMessage(with: GenericMessage(content: Confirmation(
                    messageId: UUID(),
                    type: .delivered
                )))
            self.syncMOC.saveOrRollback()
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(confirmationMessage.isZombieObject)
        }
    }

    func testThatItNotifiesWhenMessageCannotBeSent_MissingLegalholdConsent() {

        // GIVEN
        var confirmationMessage: ZMMessage!
        var token: Any?
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 403,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
        let missingLegalholdConsentFailure = Payload.ResponseFailure(
            code: 403,
            label: .missingLegalholdConsent,
            message: "",
            data: nil
        )
        let failure = NetworkError.invalidRequestError(missingLegalholdConsentFailure, response)
        syncMOC.performGroupedAndWait {

            confirmationMessage = try! self.oneToOneConversation
                .appendClientMessage(with: GenericMessage(content: Confirmation(
                    messageId: UUID(),
                    type: .delivered
                )))
            self.syncMOC.saveOrRollback()
            self.mockMessageSender.sendMessageMessage_MockError = failure

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }

            let expectation = self.customExpectation(description: "Notification fired")
            token = NotificationInContext.addObserver(
                name: ZMConversation.failedToSendMessageNotificationName,
                context: self.uiMOC.notificationContext,
                object: nil
            ) { _ in
                expectation.fulfill()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItExpiresStaleMessage() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            makeSut(hasMLSClient: true)
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            XCTAssertFalse(message.isExpired)

            // WHEN
            let didComplete = XCTestExpectation(description: "didComplete")
            self.sut.insert(object: message, isFresh: false, completion: {
                didComplete.fulfill()
            })

            wait(for: [didComplete])
            XCTAssertTrue(message.isExpired)
            XCTAssertEqual(self.mockMessageSender.sendMessageMessage_Invocations.count, 0)
        }
    }
}
