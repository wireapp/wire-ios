//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireMessageStrategy

private let testDataURL = Bundle(for: AssetV3DownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!

class AssetV3DownloadRequestStrategyTests: MessagingTest {

    var authStatus: MockClientRegistrationStatus!
    var cancellationProvider: MockTaskCancellationProvider!
    var sut: AssetV3DownloadRequestStrategy!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        authStatus = MockClientRegistrationStatus()
        cancellationProvider = MockTaskCancellationProvider()
        sut = AssetV3DownloadRequestStrategy(
            authStatus: authStatus,
            taskCancellationProvider: cancellationProvider,
            managedObjectContext: syncMOC
        )
        conversation = createConversation()
    }

    fileprivate func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        return conversation
    }
    
    fileprivate func createFileMessageWithAssetId(
        in conversation: ZMConversation,
        otrKey: Data = Data.randomEncryptionKey(),
        sha: Data  = Data.randomEncryptionKey()
        ) -> (message: ZMAssetClientMessage, assetId: String, assetToken: String)? {

        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL), version3: true) as! ZMAssetClientMessage

        let (assetId, token) = (UUID.create().transportString(), UUID.create().transportString())

        // TODO: We should replace this manual update with inserting a v3 asset as soon as we have sending support
        let uploaded = ZMGenericMessage.genericMessage(
            withUploadedOTRKey: otrKey,
            sha256: sha,
            messageID: message.nonce.transportString(),
            expiresAfter: NSNumber(value: conversation.messageDestructionTimeout)
        )

        guard let uploadedWithId = uploaded.updatedUploaded(withAssetId: assetId, token: token) else {
            XCTFail("Failed to update asset")
            return nil
        }

        message.add(uploadedWithId)
        configureForDownloading(message: message)
        XCTAssertEqual(message.version, 3)
        return (message, assetId, token)
    }

    fileprivate func configureForDownloading(message: ZMAssetClientMessage) {
        message.fileMessageData?.transferState = .downloading
        self.syncMOC.saveOrRollback()

        self.sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItGeneratesARequestToTheV3EndpointIfTheProtobufContainsAnAssetID_V3() {
        // Given
        guard let (message, assetId, token) = createFileMessageWithAssetId(in: createConversation()) else { return XCTFail("No message") }

        guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData found") }
        XCTAssert(assetData.hasUploaded())
        XCTAssertEqual(assetData.uploaded.assetId, assetId)
        XCTAssertEqual(assetData.uploaded.assetToken, token)

        // When
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // Then
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.path, "/assets/v3/\(assetId)")
        XCTAssert(request.needsAuthentication)
    }

    func testThatItGeneratesARequestToTheV3EndpointITheProtobufContainsAnAssetID_EphemeralConversation_V3() {
        // Given
        let conversation = createConversation()
        conversation.messageDestructionTimeout = 5
        guard let (message, assetId, token) = createFileMessageWithAssetId(in: conversation) else { return XCTFail("No message") }

        guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData found") }
        XCTAssert(assetData.hasUploaded())
        XCTAssertEqual(assetData.uploaded.assetId, assetId)
        XCTAssertEqual(assetData.uploaded.assetToken, token)
        XCTAssert(message.genericAssetMessage!.hasEphemeral())

        // When
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // Then
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.path, "/assets/v3/\(assetId)")
        XCTAssert(request.needsAuthentication)
    }

    func testThatItGeneratesARequestOnlyOnceForAssetMessages_V3() {
        // Given
        guard let _ = createFileMessageWithAssetId(in: createConversation()) else { return XCTFail("No message") }

        // When
        guard let _ = sut.nextRequest() else { return XCTFail("No request generated") }

        // Then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItGeneratesNoRequestsIfNotAuthenticated_V3() {
        // given
        authStatus.mockClientIsReadyForRequests = false
        _ = createFileMessageWithAssetId(in: conversation)! // V3

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItGeneratesNoRequestsIfMessageIsUploading_V3() {
        // given
        guard let (message , _, _) = createFileMessageWithAssetId(in: conversation) else { return XCTFail() } // V3
        message.fileMessageData?.transferState = .uploaded
        syncMOC.saveOrRollback()

        sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest())
    }

}

// tests on result of request
extension AssetV3DownloadRequestStrategyTests {

    func testThatItMarksDownloadAsSuccessIfSuccessfulDownloadAndDecryption_V3() {
        // given
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()

        let (message, _, _) = createFileMessageWithAssetId(in: conversation, otrKey: key, sha: sha)!

        let request = sut.nextRequest()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])

        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.downloaded.rawValue)
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_PermanentError_V3() {
        // given
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)

        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError_V3() {
        // given
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)

        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_CannotDecrypt_V3() {
        // given
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: .none)

        // when
        performIgnoringZMLogError {
            request?.complete(with: response)
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }

    func testThatItDoesNotMarkDownloadAsFailedWhenNotDownloading_V3() {
        // given
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)

        // when
        message.transferState = .uploaded
        
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.uploaded.rawValue)
    }

    func testThatItUpdatesFileDownloadProgress_V3() {
        // given
        let expectedProgress: Float = 0.5
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()

        XCTAssertEqual(message.fileMessageData?.progress, 0)

        // when
        request?.updateProgress(expectedProgress)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.fileMessageData?.progress, expectedProgress)
    }

    func testThatItSendsTheNotificationIfSuccessfulDownloadAndDecryption_V3() {

        // given
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()

        let _ = createFileMessageWithAssetId(in: conversation, otrKey: key, sha: sha)!

        let notificationExpectation = self.expectation(description: "Notification fired")

        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![AssetDownloadRequestStrategyNotification.downloadStartTimestampKey])
            notificationExpectation.fulfill()
        }

        let request = sut.nextRequest()
        request?.markStartOfUploadTimestamp()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])

        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

    }
    
    func testThatItRecategorizeMessageAfterDownloadingAssetContent() {
        
        // given
        let plainTextData = self.verySmallJPEGData()
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let messageId = UUID.create()
        
        let selfClient = createSelfClient()
        
        let asset = ZMAssetBuilder()
            .setOriginal(ZMAssetOriginalBuilder()
                .setMimeType("image/jpeg")
                .setSize(UInt64(plainTextData.count))
                .setImage(ZMAssetImageMetaDataBuilder()
                    .setWidth(100)
                    .setHeight(100)
                    .setTag("medium")))
            .setUploaded(ZMAssetRemoteDataBuilder()
                .setOtrKey(key)
                .setSha256(sha)
                .setAssetId("someId")
                .setAssetToken("someToken"))
            .build()
        
        let genericMessage = ZMGenericMessage.genericMessage(asset: asset!, messageID: messageId.transportString())
        
        let dict = ["recipient": selfClient.remoteIdentifier, "sender": selfClient.remoteIdentifier, "text": genericMessage.data().base64String()] as NSDictionary
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
            "type": "conversation.otr-message-add",
            "data":dict,
            "conversation":conversation.remoteIdentifier!.transportString(),
            "time":Date(timeIntervalSince1970: 555555).transportString()] as NSDictionary), uuid: nil)
        
        let message = ZMOTRMessage.messageUpdateResult(from: updateEvent, in: syncMOC, prefetchResult: nil).message as! ZMAssetClientMessage
        message.visibleInConversation = conversation
        message.transferState = .downloading
        
        XCTAssertEqual(message.category, [.image, .excludedFromCollection])
        
        sut.contextChangeTrackers.forEach { (tracker) in
            tracker.objectsDidChange([message])
        }
        
        let request = sut.nextRequest()
        request?.markStartOfUploadTimestamp()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
        
        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(message.category, [.image])
    }

    func testThatItSendsTheNotificationIfCannotDownload_V3() {
        // given

        let notificationExpectation = self.expectation(description: "Notification fired")

        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![AssetDownloadRequestStrategyNotification.downloadStartTimestampKey])
            notificationExpectation.fulfill()
        }

        let _ = createFileMessageWithAssetId(in: conversation)!
        let request = sut.nextRequest()
        request?.markStartOfUploadTimestamp()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
        
        // when
        request?.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK : - Download Cancellation

extension AssetV3DownloadRequestStrategyTests {

    func testThatItInformsTheTaskCancellationProviderToCancelARequestForAnAssetMessageWhenItReceivesTheNotification_V3() {
        // given
        let (message, _, _) = createFileMessageWithAssetId(in: conversation)!
        XCTAssertNotNil(message.objectID)

        // given the task has been created
        guard let request = sut.nextRequest() else { return XCTFail("No request created") }

        request.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let identifier = message.associatedTaskIdentifier
        XCTAssertNotNil(identifier)

        // when the transfer is cancelled
        message.fileMessageData?.cancelTransfer()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then the cancellation provider should be informed to cancel the request
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 1)
        let cancelledIdentifier = cancellationProvider.cancelledIdentifiers.first
        XCTAssertEqual(cancelledIdentifier, identifier)

        // It should nil-out the identifier as it has been cancelled
        XCTAssertNil(message.associatedTaskIdentifier)
    }
    
}

