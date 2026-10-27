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

import GenericMessageProtocol
import WireTransport
import XCTest

@testable import WireDataModel
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

    func testRestoredPendingDeletionKeepsUncertainOriginalOutOfTheSendQueue() throws {
        try syncMOC.performAndWait {
            let message = try XCTUnwrap(groupConversation.appendText(content: "held original") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            let content = try XCTUnwrap(message.underlyingMessage).serializedData()
            let attempt = try message.prepareOutboxAttempt(payload: content)
            try message.markOutboxAttemptSending(attempt)
            try message.requestOutboxDeletion(.everyone)
            try syncMOC.save()
            // Recovery must continue enrolled work even when new enrollment is disabled.
            syncMOC.offlinePendingMessagesEnabled = false

            var completed = false
            sut.enqueueOutboxMessage(message, isFresh: false) { completed = true }
            sut.addTrackedObjects([message])

            XCTAssertTrue(completed)
            XCTAssertEqual(message.outboxState, .uncertain)
            XCTAssertTrue(message.hasPendingOutboxDeletion)
            XCTAssertFalse(message.isExpired)
            XCTAssertTrue(message.outboxDeletionMessages.isEmpty)
            XCTAssertEqual(try message.loadOutboxPayload(), content)
            XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
        }
    }

    func testRestoredDeletionControlIsQueuedWithoutReopeningTheAcceptedOriginal() throws {
        try syncMOC.performAndWait {
            sut.tearDown()
            sut = ClientMessageRequestStrategy(
                context: syncMOC, localNotificationDispatcher: localNotificationDispatcher,
                messageSender: mockMessageSender, reachability: PendingMessageReachability()
            )
            let message = try XCTUnwrap(groupConversation.appendText(content: "accepted original") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            let content = try XCTUnwrap(message.underlyingMessage).serializedData()
            let original = try message.prepareOutboxAttempt(payload: content)
            try message.markOutboxAttemptSending(original)
            message.markAsSent()
            try message.completeOutboxAttempt(original.identifier)
            try message.requestOutboxDeletion(.everyone)
            let marker = try XCTUnwrap(message.outboxDeletionMessages.first)
            let payload = try XCTUnwrap(marker.underlyingMessage).serializedData()
            let deletion = try marker.prepareOutboxAttempt(payload: payload)
            try marker.markOutboxAttemptSending(deletion)
            try syncMOC.save()
            syncMOC.offlinePendingMessagesEnabled = false

            sut.insert(object: marker, isFresh: false, completion: {})
            sut.addTrackedObjects([message, marker])
            sut.objectsDidChange([message, marker])

            XCTAssertEqual(marker.outboxState, .queued)
            XCTAssertNotNil(marker.outboxNextAttemptAt)
            XCTAssertEqual(try marker.loadOutboxPayload(), payload)
            XCTAssertEqual(message.outboxState, .sent)
            XCTAssertTrue(message.delivered)
            XCTAssertTrue(message.hasPendingOutboxDeletion)
            XCTAssertEqual(message.outboxDeletionMessages.count, 1)
            XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
            sut.tearDown()
        }
    }

    func testContextClosureCancelsAWaitingOutboxTaskWhileItsStrategyRemainsAlive() async throws {
        let started = expectation(description: "outbox task started waiting")
        let cancelled = expectation(description: "context closure cancels waiting task")
        let completed = expectation(description: "queued completion released")
        completed.assertForOverFulfill = true
        let original = try await syncMOC.perform {
            let message = try XCTUnwrap(self.groupConversation.appendText(content: "waiting") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            try self.syncMOC.save()
            return message
        }
        let messageID = original.objectID
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = syncMOC.persistentStoreCoordinator
        context.performAndWait { context.markAsSyncContext() }
        syncMOC.performAndWait { sut.tearDown() }
        mockMessageSender.sendMessageMessage_MockMethod = { _ in
            started.fulfill()
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                cancelled.fulfill()
                throw error
            }
        }
        try await context.perform {
            self.sut = ClientMessageRequestStrategy(
                context: context, localNotificationDispatcher: self.localNotificationDispatcher,
                messageSender: self.mockMessageSender
            )
            let message = try XCTUnwrap(context.existingObject(with: messageID) as? ZMClientMessage)
            self.sut.enqueueOutboxMessage(message, isFresh: false) { completed.fulfill() }
        }
        defer { context.performAndWait { sut.tearDown() } }
        await fulfillment(of: [started], timeout: 5)

        context.tearDown()

        await fulfillment(of: [cancelled, completed], timeout: 1)
        await syncMOC.perform {
            self.syncMOC.refresh(original, mergeChanges: false)
            XCTAssertEqual(original.outboxState, .queued)
            XCTAssertFalse(original.isExpired)
            XCTAssertNil(original.outboxAttemptIdentifier)
        }
        XCTAssertEqual(mockMessageSender.sendMessageMessage_Invocations.count, 1)
    }

    func testReconnectAfterContextClosureReleasesQueuedWorkWithoutSendingIt() async throws {
        let completed = expectation(description: "closed context releases queued completion")
        completed.assertForOverFulfill = true
        let reachability = PendingMessageReachability()
        let original = try await syncMOC.perform {
            let message = try XCTUnwrap(self.groupConversation.appendText(content: "offline") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            try self.syncMOC.save()
            return message
        }
        let messageID = original.objectID
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = syncMOC.persistentStoreCoordinator
        context.performAndWait { context.markAsSyncContext() }
        syncMOC.performAndWait { sut.tearDown() }
        try await context.perform {
            self.sut = ClientMessageRequestStrategy(
                context: context, localNotificationDispatcher: self.localNotificationDispatcher,
                messageSender: self.mockMessageSender, reachability: reachability
            )
            let message = try XCTUnwrap(context.existingObject(with: messageID) as? ZMClientMessage)
            self.sut.enqueueOutboxMessage(message, isFresh: false) { completed.fulfill() }
        }
        context.tearDown()

        reachability.reconnect()
        await fulfillment(of: [completed], timeout: 5)

        XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
        await syncMOC.perform {
            self.syncMOC.refresh(original, mergeChanges: false)
            XCTAssertEqual(original.outboxState, .queued)
            XCTAssertFalse(original.isExpired)
        }
        context.performAndWait { sut.tearDown() }
    }

    func testShareScopeDoesNotClaimOrExpireMainAppOutboxMessages() throws {
        try syncMOC.performAndWait {
            let queued = try XCTUnwrap(groupConversation.appendText(content: "main app outbox") as? ZMClientMessage)
            try queued.enqueueInOutbox(operation: .initialMessage)
            try syncMOC.save()
            syncMOC.disableOfflinePendingMessageProcessing()
            let legacy = try XCTUnwrap(groupConversation.appendText(content: "share extension") as? ZMClientMessage)
            let predicate = ClientMessageRequestStrategy.shouldBeSentPredicate(context: syncMOC)
            XCTAssertFalse(predicate.evaluate(with: queued))
            XCTAssertTrue(predicate.evaluate(with: legacy))
            XCTAssertEqual(legacy.outboxState, .notEnrolled)

            sut.insert(object: queued, isFresh: false, completion: {})

            XCTAssertEqual(queued.outboxState, .queued)
            XCTAssertFalse(queued.isExpired)
            XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
        }
    }

    func testRestoredUploadedAssetWaitsOfflineThenSendsItsExistingReference() async throws {
        let sent = expectation(description: "uploaded asset reference sent after reconnect")
        let reachability = PendingMessageReachability()
        try syncMOC.performAndWait {
            sut.tearDown()
            sut = ClientMessageRequestStrategy(
                context: syncMOC, localNotificationDispatcher: localNotificationDispatcher,
                messageSender: mockMessageSender, reachability: reachability
            )
            let message = try XCTUnwrap(groupConversation.appendImage(
                SendableImage(name: "pending.jpg", utType: .jpeg, data: verySmallJPEGData()), nonce: UUID()
            ) as? ZMAssetClientMessage)
            var content = try XCTUnwrap(message.underlyingMessage)
            content.updateAsset(withUploadedOTRKey: Data.randomEncryptionKey(), sha256: Data.zmRandomSHA256Key())
            content.updateUploaded(assetId: "already-uploaded", token: nil, domain: "wire.com")
            try message.setUnderlyingMessage(content)
            try message.enqueueInOutbox(operation: .initialMessage)
            message.updateTransferState(.uploaded, synchronize: false)
            try syncMOC.save()
            mockMessageSender.sendMessageMessage_MockMethod = { entity in
                try await entity.context.perform {
                    let row = try XCTUnwrap(entity as? ZMAssetClientMessage)
                    XCTAssertEqual(row.underlyingMessage?.assetData?.uploaded.assetID, "already-uploaded")
                    let payload = try XCTUnwrap(row.underlyingMessage).serializedData()
                    let attempt = try row.prepareOutboxAttempt(payload: payload)
                    try row.markOutboxAttemptSending(attempt)
                    row.markAsSent()
                    try row.completeOutboxAttempt(attempt.identifier)
                    sent.fulfill()
                }
            }
            let strategy = AssetClientMessageRequestStrategy(
                managedObjectContext: syncMOC, messageSender: mockMessageSender, outboxStrategy: sut
            )
            strategy.insert(object: message, isFresh: false, completion: {})
            XCTAssertFalse(message.isExpired)
            XCTAssertEqual(message.outboxState, .queued)
            XCTAssertTrue(mockMessageSender.sendMessageMessage_Invocations.isEmpty)
        }

        reachability.reconnect()
        await fulfillment(of: [sent], timeout: 5)
        syncMOC.performAndWait { sut.tearDown() }
    }

    func testRestoredOutboxWaitsOfflineWithoutExpiring() throws {
        try syncMOC.performAndWait {
            let reachability = PendingMessageReachability()
            sut.tearDown()
            sut = ClientMessageRequestStrategy(
                context: syncMOC,
                localNotificationDispatcher: localNotificationDispatcher,
                messageSender: mockMessageSender,
                reachability: reachability
            )
            let message = try XCTUnwrap(groupConversation.appendText(content: "offline") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            try syncMOC.save()

            sut.contextChangeTrackers.forEach { $0.addTrackedObjects([message]) }

            XCTAssertEqual(mockMessageSender.sendMessageMessage_Invocations.count, 0)
            XCTAssertEqual(message.outboxState, .queued)
            XCTAssertFalse(message.isExpired)
            XCTAssertNil(message.expirationDate)
            sut.tearDown()
        }
    }

    func testReconnectWakesQueuedMessageWithoutManualRetry() async throws {
        let sent = expectation(description: "queued message sent after reachability returns")
        let reachability = PendingMessageReachability()
        try syncMOC.performAndWait {
            sut.tearDown()
            sut = ClientMessageRequestStrategy(
                context: syncMOC,
                localNotificationDispatcher: localNotificationDispatcher,
                messageSender: mockMessageSender,
                reachability: reachability
            )
            mockMessageSender.sendMessageMessage_MockMethod = { message in
                try await message.context.perform {
                    let row = try XCTUnwrap(message as? ZMClientMessage)
                    let payload = try XCTUnwrap(row.underlyingMessage).serializedData()
                    let attempt = try row.prepareOutboxAttempt(payload: payload)
                    try row.markOutboxAttemptSending(attempt)
                    row.markAsSent()
                    try row.completeOutboxAttempt(attempt.identifier)
                    sent.fulfill()
                }
            }
            let message = try XCTUnwrap(groupConversation.appendText(content: "offline") as? ZMClientMessage)
            try message.enqueueInOutbox(operation: .initialMessage)
            try syncMOC.save()
            sut.contextChangeTrackers.forEach { $0.objectsDidChange([message]) }
            XCTAssertEqual(mockMessageSender.sendMessageMessage_Invocations.count, 0)
        }

        reachability.reconnect()
        await fulfillment(of: [sent], timeout: 5)
        syncMOC.performAndWait { sut.tearDown() }
    }
}

private final class PendingMessageReachability: NSObject, ReachabilityProvider {
    var mayBeReachable = false
    var oldMayBeReachable = false
    private var callback: ReachabilityObserverBlock?

    func add(_ observer: ZMReachabilityObserver, queue: OperationQueue?) -> Any { NSObject() }

    func addReachabilityObserver(on queue: OperationQueue?, block: @escaping ReachabilityObserverBlock) -> Any {
        callback = block
        return NSObject()
    }

    func reconnect() {
        oldMayBeReachable = mayBeReachable
        mayBeReachable = true
        callback?(self)
    }
}

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
